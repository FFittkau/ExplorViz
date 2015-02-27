package explorviz.plugin_server.anomalydetection;

import java.util.HashMap;

import explorviz.plugin_client.attributes.IPluginKeys;
import explorviz.plugin_client.attributes.TreeMapLongDoubleIValue;
import explorviz.plugin_server.anomalydetection.aggregation.TraceAggregator;
import explorviz.plugin_server.anomalydetection.anomalyscore.CalculateAnomalyScore;
import explorviz.plugin_server.anomalydetection.anomalyscore.InterpreteAnomalyScore;
import explorviz.plugin_server.anomalydetection.forecast.AbstractForecaster;
import explorviz.plugin_server.anomalydetection.util.ADThreadPool;
import explorviz.plugin_server.anomalydetection.util.IThreadable;
import explorviz.plugin_server.rootcausedetection.exception.RootCauseThreadingException;
import explorviz.shared.model.*;
import explorviz.shared.model.System;

/**
 * Threadable class that does the anomaly detection. The tasks are splitted on
 * CommunicationClazz-level.
 *
 * @author Enno Schwanke
 *
 */
public class AnnotateTimeSeriesAndAnomalyScore implements IThreadable<CommunicationClazz, Long> {

	/**
	 * For each CommunicationClazz (Method) that is called an item is added to a
	 * threadpool. Afterwards the threadpool is started and the available
	 * threads take the items in the pool and annotate them.
	 *
	 * @param landscape
	 *            The anomaly detection is done based on a given landscape
	 */
	public void doAnomalyDetection(Landscape landscape) {
		final ADThreadPool<CommunicationClazz, Long> pool = new ADThreadPool<>(this, Runtime
				.getRuntime().availableProcessors(), landscape.getHash());
		for (System system : landscape.getSystems()) {
			for (NodeGroup nodeGroup : system.getNodeGroups()) {
				for (Node node : nodeGroup.getNodes()) {
					for (Application application : node.getApplications()) {
						application.putGenericBooleanData(IPluginKeys.WARNING_ANOMALY, false);
						application.putGenericBooleanData(IPluginKeys.ERROR_ANOMALY, false);
						for (Component component : application.getComponents()) {
							component.putGenericBooleanData(IPluginKeys.WARNING_ANOMALY, false);
							component.putGenericBooleanData(IPluginKeys.ERROR_ANOMALY, false);
							recursiveComponentSplitting(component);
						}
						for (CommunicationClazz communication : application.getCommunications()) {
							communication.putGenericBooleanData(IPluginKeys.WARNING_ANOMALY, false);
							communication.putGenericBooleanData(IPluginKeys.ERROR_ANOMALY, false);
							pool.addData(communication);
						}
					}
				}
			}
		}
		try {
			pool.startThreads();
		} catch (final InterruptedException e) {
			throw new RootCauseThreadingException(
					"AnnotateTimeSeriesAndAnomalyScoreThreaded#calculate(...): Threading interrupted, broken output.");
		}
	}

	private static void recursiveComponentSplitting(Component component) {
		for (Clazz clazz : component.getClazzes()) {
			clazz.putGenericBooleanData(IPluginKeys.WARNING_ANOMALY, false);
			clazz.putGenericBooleanData(IPluginKeys.ERROR_ANOMALY, false);
		}
		for (Component childComponent : component.getChildren()) {
			childComponent.putGenericBooleanData(IPluginKeys.WARNING_ANOMALY, false);
			childComponent.putGenericBooleanData(IPluginKeys.ERROR_ANOMALY, false);
			recursiveComponentSplitting(childComponent);
		}
	}

	@Override
	public void calculate(CommunicationClazz input, Long attr) {
		annotateTimeSeriesAndAnomalyScore(input, attr);
	}

	private static void annotateTimeSeriesAndAnomalyScore(CommunicationClazz element, long timestamp) {

		TreeMapLongDoubleIValue responseTimes = (TreeMapLongDoubleIValue) element
				.getGenericData(IPluginKeys.TIMESTAMP_TO_RESPONSE_TIME);
		if (responseTimes == null) {
			responseTimes = new TreeMapLongDoubleIValue();
		}
		TreeMapLongDoubleIValue predictedResponseTimes = (TreeMapLongDoubleIValue) element
				.getGenericData(IPluginKeys.TIMESTAMP_TO_PREDICTED_RESPONSE_TIME);
		if (predictedResponseTimes == null) {
			predictedResponseTimes = new TreeMapLongDoubleIValue();
		}
		TreeMapLongDoubleIValue anomalyScores = (TreeMapLongDoubleIValue) element
				.getGenericData(IPluginKeys.TIMESTAMP_TO_ANOMALY_SCORE);
		if (anomalyScores == null) {
			anomalyScores = new TreeMapLongDoubleIValue();
		}

		HashMap<Long, RuntimeInformation> traceIdToRuntimeMap = (HashMap<Long, RuntimeInformation>) element
				.getTraceIdToRuntimeMap();
		double responseTime = new TraceAggregator().aggregateTraces(traceIdToRuntimeMap);
		responseTimes.put(timestamp, responseTime);

		double predictedResponseTime = AbstractForecaster.forecast(responseTimes,
				predictedResponseTimes);
		predictedResponseTimes.put(timestamp, predictedResponseTime);

		double anomalyScore = new CalculateAnomalyScore().getAnomalyScore(responseTime,
				predictedResponseTime);
		anomalyScores.put(timestamp, anomalyScore);
		boolean[] errorWarning = new InterpreteAnomalyScore().interprete(anomalyScore);
		if (errorWarning[1]) {
			element.putGenericBooleanData(IPluginKeys.WARNING_ANOMALY, true);
			element.putGenericBooleanData(IPluginKeys.ERROR_ANOMALY, true);
			annotateParentHierachy(element, true);
		} else if (errorWarning[0]) {
			element.putGenericBooleanData(IPluginKeys.WARNING_ANOMALY, true);
			annotateParentHierachy(element, false);
		}

		element.putGenericData(IPluginKeys.TIMESTAMP_TO_RESPONSE_TIME, responseTimes);
		element.putGenericData(IPluginKeys.TIMESTAMP_TO_PREDICTED_RESPONSE_TIME,
				predictedResponseTimes);
		element.putGenericData(IPluginKeys.TIMESTAMP_TO_ANOMALY_SCORE, anomalyScores);
	}

	private static void annotateParentHierachy(CommunicationClazz element, boolean warningOrError) {
		Clazz clazz = element.getTarget();
		if (warningOrError) {
			clazz.putGenericBooleanData(IPluginKeys.WARNING_ANOMALY, true);
			clazz.putGenericBooleanData(IPluginKeys.ERROR_ANOMALY, true);
		} else {
			clazz.putGenericBooleanData(IPluginKeys.WARNING_ANOMALY, true);
		}

		annotateParentComponent(clazz.getParent(), warningOrError);
	}

	private static void annotateParentComponent(Component component, boolean warningOrError) {
		Component parentComponent = component.getParentComponent();
		if (warningOrError) {
			parentComponent.putGenericBooleanData(IPluginKeys.WARNING_ANOMALY, true);
			parentComponent.putGenericBooleanData(IPluginKeys.ERROR_ANOMALY, true);
		} else {
			parentComponent.putGenericBooleanData(IPluginKeys.WARNING_ANOMALY, true);
		}

		if (parentComponent.getParentComponent() != null) {
			annotateParentComponent(parentComponent.getParentComponent(), warningOrError);
		} else {
			Application application = parentComponent.getBelongingApplication();
			if (warningOrError) {
				application.putGenericBooleanData(IPluginKeys.WARNING_ANOMALY, true);
				application.putGenericBooleanData(IPluginKeys.ERROR_ANOMALY, true);
			} else {
				application.putGenericBooleanData(IPluginKeys.WARNING_ANOMALY, true);
			}
		}
	}
}
