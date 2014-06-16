package explorviz.visualization.engine.picking

import explorviz.visualization.engine.main.WebGLStart
import explorviz.visualization.engine.math.Ray

import java.util.ArrayList
import java.util.HashMap
import java.util.List
import explorviz.visualization.engine.main.ProjectionHelper

class ObjectPicker {
	val static eventAndObjects = new HashMap<EventType, List<EventObserver>>

	def static addObject(EventObserver object, EventType event) {
		var objects = eventAndObjects.get(event)

		objects.add(object)

		eventAndObjects.put(event, objects)
	}

	def static removeObject(EventObserver object, EventType event) {
		var objects = eventAndObjects.get(event)

		objects.remove(objects)
	}

	def static clear() {
		eventAndObjects.clear()
		doInit()
	}

	def static init() {
		doInit()
	}

	def static doInit() {
		eventAndObjects.put(EventType::DOUBLECLICK_EVENT, new ArrayList<EventObserver>)
		eventAndObjects.put(EventType::CLICK_EVENT, new ArrayList<EventObserver>)
		eventAndObjects.put(EventType::MOUSEMOVE_EVENT, new ArrayList<EventObserver>)
		eventAndObjects.put(EventType::RIGHTCLICK_EVENT, new ArrayList<EventObserver>)
	}

	def static void handleDoubleClick(int x, int y, int absoluteWidth, int absoluteHeight) {
		pickObject(x, y, absoluteWidth, absoluteHeight, EventType::DOUBLECLICK_EVENT)
	}

	def static void handleClick(int x, int y, int absoluteWidth, int absoluteHeight) {
		pickObject(x, y, absoluteWidth, absoluteHeight, EventType::CLICK_EVENT)
	}

	def static void handleMouseMove(int x, int y, int absoluteWidth, int absoluteHeight) {
		pickObject(x, y, absoluteWidth, absoluteHeight, EventType::MOUSEMOVE_EVENT)
	}

	def static void handleRightClick(int x, int y, int absoluteWidth, int absoluteHeight) {
		pickObject(x, y, absoluteWidth, absoluteHeight, EventType::RIGHTCLICK_EVENT)
	}

	private def static pickObject(int x, int y, int absoluteWidth, int absoluteHeight, EventType event) {
		if (hasEventHandlers(event) && WebGLStart::explorVizVisible) {
			val origin = ProjectionHelper::unproject(x, y, 0, absoluteWidth, absoluteHeight - 100)
			var direction = ProjectionHelper::unprojectDirection(0, 0, -100000f)
			
			val ray = new Ray(origin, direction)

			val intersectsList = getIntersectsList(ray, event)

			val intersectObject = getTopEntityFromList(ray, intersectsList)
			
			if (intersectObject != null) {
				val clickEvent = new ClickEvent()
				clickEvent.positionX = origin.x
				clickEvent.positionX = origin.y
				clickEvent.originalClickX = x
				clickEvent.originalClickY = y
				clickEvent.object = intersectObject
				
				fireEvent(event, intersectObject, clickEvent)
			}
		}
	}

	private def static hasEventHandlers(EventType event) {
		eventAndObjects.get(event) != null && !eventAndObjects.get(event).empty
	}

	private def static getIntersectsList(Ray ray, EventType event) {
		val intersectsList = new ArrayList<EventObserver>
		val objects = eventAndObjects.get(event)

		for (object : objects) {
			for (primitiveObject : object.primitiveObjects) {
				if (ray.intersects(primitiveObject)) {
					intersectsList.add(object)
				}
			}
		}

		intersectsList
	}

	private def static EventObserver getTopEntityFromList(Ray ray, List<EventObserver> entities) {
		var topCoefficient = Float::MAX_VALUE
		var EventObserver topEntity = null

		for (entity : entities) {
			for (primitiveObject : entity.primitiveObjects) {
				val currentCoefficient = ray.getIntersectCoefficient(primitiveObject)

				if (topCoefficient > currentCoefficient) {
					topCoefficient = currentCoefficient
					topEntity = entity
				}
			}
		}
		
		return topEntity
	}

	private def static fireEvent(EventType event, EventObserver intersectObject, ClickEvent clickEvent) {
		if (event == EventType::CLICK_EVENT) {
			intersectObject.mouseClickHandler.handleClick(clickEvent)
		} else if (event == EventType::DOUBLECLICK_EVENT) {
			intersectObject.mouseDoubleClickHandler.handleDoubleClick(clickEvent)
		} else if (event == EventType::RIGHTCLICK_EVENT) {
			intersectObject.mouseRightClickHandler.handleRightClick(clickEvent)
		} else if (event == EventType::MOUSEMOVE_EVENT) {
			intersectObject.mouseHoverHandler.handleHover(clickEvent)
		}
	}
}
