package explorviz.visualization.highlighting

import com.google.gwt.safehtml.shared.SafeHtmlUtils
import com.google.gwt.user.client.Timer
import explorviz.shared.model.Application
import explorviz.shared.model.CommunicationClazz
import explorviz.shared.model.helper.CommunicationAppAccumulator
import explorviz.visualization.engine.main.SceneDrawer
import java.util.ArrayList
import java.util.List

import static explorviz.visualization.highlighting.TraceReplayer.*
import explorviz.visualization.engine.navigation.Camera
import explorviz.visualization.renderer.ApplicationRenderer
import explorviz.visualization.engine.math.Matrix44f
import explorviz.visualization.engine.math.Vector4f
import explorviz.visualization.engine.math.Vector3f

class TraceReplayer {
	static val PLAYBACK_SPEED_IN_MS = 1400

	static var Application application
	static var Long traceId
	static var List<CommunicationAppAccumulator> belongingAppCommunications = new ArrayList<CommunicationAppAccumulator>

	public static var CommunicationClazz currentlyHighlightedCommu
	public static var int currentIndex = 0
	static var int maxIndex = 0

	static TraceReplayer.PlayTimer playTimer

	static CameraFlyTimer cameraFly

	public def static reset() {
		application = null
		currentlyHighlightedCommu = null
		belongingAppCommunications.clear()
		currentIndex = 0

		TraceReplayerJS::closeDialog()
		if (playTimer != null) {
			playTimer.cancel
		}

		if (cameraFly != null) {
			cameraFly.cancel
		}
	}

	def static replayInit(Long traceIdP, Application applicationP) {
		reset()

		application = applicationP
		traceId = traceIdP
		fillBelongingAppCommunications(false)

		val firstCommu = findNextCommu(true)
		val tableInfos = createTableInformation(firstCommu)

		TraceReplayerJS::openDialog(traceId.toString(), tableInfos)

		if (application != null) {
			SceneDrawer::createObjectsFromApplication(application, true)
		}
	}

	def static String createTableInformation(CommunicationClazz commu) {
		var tableInformation = ""

		tableInformation +=
			"<tr><th>Position:</th><td style='text-align: left'>" + currentIndex + " of " + maxIndex + "</td></tr>"
		tableInformation += "<tr><th>Caller:</th><td style='text-align: left'>" +
			SafeHtmlUtils::htmlEscape(commu.source.name) + "</td></tr>"
		tableInformation += "<tr><th>Callee:</th><td style='text-align: left'>" +
			SafeHtmlUtils::htmlEscape(commu.target.name) + "</td></tr>"
		tableInformation += "<tr><th>Method:</th><td style='text-align: left'>" +
			SafeHtmlUtils::htmlEscape(commu.methodName) + "(..)</td></tr>"

		val runtime = commu.traceIdToRuntimeMap.get(traceId)

		tableInformation += "<tr><th>Avg. Time:</th><td style='text-align: left'>" +
			convertToMilliSecondTime(runtime.averageResponseTime) + " ms</td></tr>"

		var modelView = new Matrix44f();
		modelView = Matrix44f.rotationX(33).mult(modelView)
		modelView = Matrix44f.rotationY(45).mult(modelView)

		val viewCenterPoint = ApplicationRenderer::viewCenterPoint
		val rotatedSourceCenter = modelView.mult(new Vector4f(commu.source.centerPoint.sub(viewCenterPoint), 1f))
		val rotatedTargetCenter = modelView.mult(new Vector4f(commu.target.centerPoint.sub(viewCenterPoint), 1f))
		
		val nextCommu = findNextCommu(false)

		if (cameraFly != null) {
			cameraFly.cancel
		}

		cameraFly = new CameraFlyTimer(new Vector3f(rotatedSourceCenter.x * -1, rotatedSourceCenter.y * -1, -65f),
			new Vector3f(rotatedTargetCenter.x * -1, rotatedTargetCenter.y * -1, -65f))
		cameraFly.scheduleRepeating(Math.round(1000f / 30))
		

		currentlyHighlightedCommu = commu

		tableInformation
	}

	static class CameraFlyTimer extends Timer {
		val fps = 30
		val Vector3f source
		val Vector3f oneStepDistance
		var int currentStep = 0

		new(Vector3f source, Vector3f target) {
			this.source = source
			val distance = target.sub(source)

			this.oneStepDistance = distance.scaleToLength(distance.length / fps)
		}

		override run() {
			if (currentStep < fps) {
				Camera::focus(source.add(oneStepDistance.mult(currentStep)))
				currentStep++
			} else {
				cancel
			}
		}
	}

	def static fillBelongingAppCommunications(boolean withSelfEdges) {
		var maxOrderIndex = 0
		for (commu : application.communicationsAccumulated) {
			val runtime = seekCommuWithTraceId(commu, withSelfEdges)
			if (runtime != null) {
				belongingAppCommunications.add(commu)
				for (orderIndex : runtime.orderIndexes) {
					if (orderIndex > maxOrderIndex) {
						maxOrderIndex = orderIndex
					}
				}
			}
		}

		maxIndex = maxOrderIndex
	}

	private def static seekCommuWithTraceId(CommunicationAppAccumulator commu, boolean withSelfEdges) {
		for (aggCommu : commu.aggregatedCommunications) {
			val runtime = aggCommu.traceIdToRuntimeMap.get(traceId)
			if (runtime != null) {
				if (withSelfEdges || (aggCommu.source != aggCommu.target)) {
					return runtime
				}
			}
		}
		null
	}

	def static CommunicationClazz findCommuWithIndex(int index) {
		for (belongingAppCommunication : belongingAppCommunications) {
			for (aggCommu : belongingAppCommunication.aggregatedCommunications) {
				val runtime = aggCommu.traceIdToRuntimeMap.get(traceId)
				if (runtime != null && runtime.orderIndexes.contains(index)) {
					return aggCommu
				}
			}
		}
		return null
	}

	private def static String convertToMilliSecondTime(float x) {
		val result = (x / (1000 * 1000)).toString()

		result.substring(0, Math.min(result.indexOf('.') + 3, result.length - 1))
	}

	def static play() {
		if (playTimer != null)
			playTimer.cancel
		playTimer = new TraceReplayer.PlayTimer()
		playTimer.scheduleRepeating(PLAYBACK_SPEED_IN_MS)
	}

	def static pause() {
		if (playTimer != null)
			playTimer.cancel
	}

	def static void previous() {
		val commu = findPreviousCommu()
		if (commu != null) {
			val tableInfos = createTableInformation(commu)
			TraceReplayerJS::updateInformation(tableInfos)

			if (application != null) {
				SceneDrawer::createObjectsFromApplication(application, true)
			}
		}
	}

	def static CommunicationClazz findPreviousCommu() {
		while (currentIndex > 0) {
			currentIndex--
			val commu = findCommuWithIndex(currentIndex)
			if (commu != null) {
				return commu
			}
		}

		return null
	}

	def static void next() {
		val commu = findNextCommu(true)
		if (commu != null) {
			val tableInfos = createTableInformation(commu)
			TraceReplayerJS::updateInformation(tableInfos)

			if (application != null) {
				SceneDrawer::createObjectsFromApplication(application, true)
			}
		}
	}

	def static CommunicationClazz findNextCommu(boolean withIndexIncrease) {
		var index = currentIndex
		while (currentIndex < maxIndex) {
			index++
			val commu = findCommuWithIndex(index)
			if (commu != null) {
				if (withIndexIncrease)
					currentIndex = index
				return commu
			}
		}
		if (withIndexIncrease)
			currentIndex = index
		return null
	}

	def static void showSelfEdges() {
		belongingAppCommunications.clear
		fillBelongingAppCommunications(true)
	}

	def static void hideSelfEdges() {
		belongingAppCommunications.clear
		fillBelongingAppCommunications(false)
	}

	static class PlayTimer extends Timer {
		override run() {
			if (currentIndex < maxIndex) {
				next()
			} else {
				this.cancel
			}
		}
	}
}