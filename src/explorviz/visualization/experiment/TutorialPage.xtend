package explorviz.visualization.experiment

import explorviz.visualization.engine.main.WebGLStart
import explorviz.visualization.engine.navigation.Navigation
import explorviz.visualization.main.PageControl
import explorviz.visualization.view.IPage

import static explorviz.visualization.experiment.Experiment.*

class TutorialPage implements IPage {
	override render(PageControl pageControl) {
		pageControl.setView("")
		
		Navigation::registerWebGLKeys()
		Experiment::loadTutorial()
		Experiment::getTutorialText(Experiment::tutorialStep)
	    Experiment::tutorial = true
	    ExperimentJS.showTutorialDialog()   
		WebGLStart::initWebGL()
	    
	}
	
}