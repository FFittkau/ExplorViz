package explorviz.visualization.main

import explorviz.visualization.landscapeexchange.LandscapeExchangeServiceAsync
import com.google.gwt.core.client.GWT
import explorviz.visualization.landscapeexchange.LandscapeExchangeService
import com.google.gwt.user.client.rpc.ServiceDefTarget
import explorviz.visualization.experiment.services.JSONServiceAsync
import explorviz.visualization.experiment.services.JSONService
import explorviz.visualization.experiment.services.QuestionServiceAsync
import explorviz.visualization.experiment.services.QuestionService
import explorviz.visualization.experiment.services.TutorialServiceAsync
import explorviz.visualization.experiment.services.TutorialService
import explorviz.visualization.experiment.services.ConfigurationServiceAsync
import explorviz.visualization.experiment.services.ConfigurationService
import explorviz.visualization.login.LoginServiceAsync
import explorviz.visualization.login.LoginService
import explorviz.shared.resources.DialogMessages

class Util {

	def static getLandscapeService() {
		val LandscapeExchangeServiceAsync landscapeExchangeService = GWT::create(typeof(LandscapeExchangeService))
		val endpoint = landscapeExchangeService as ServiceDefTarget
		val moduleRelativeURL = GWT::getModuleBaseURL() + "landscapeexchange"
		endpoint.serviceEntryPoint = moduleRelativeURL
		return landscapeExchangeService
	}

	def static getJSONService() {
		val JSONServiceAsync jsonService = GWT::create(typeof(JSONService))
		val endpoint = jsonService as ServiceDefTarget
		endpoint.serviceEntryPoint = GWT::getModuleBaseURL() + "jsonservice"
		return jsonService
	}

	def static getQuestionService() {
		val QuestionServiceAsync questionService = GWT::create(typeof(QuestionService))
		val endpoint = questionService as ServiceDefTarget
		endpoint.serviceEntryPoint = GWT::getModuleBaseURL() + "questionservice"
		return questionService
	}
	
	def static getTutorialService() {
		val TutorialServiceAsync tutorialService = GWT::create(typeof(TutorialService))
		val endpoint = tutorialService as ServiceDefTarget
		endpoint.serviceEntryPoint = GWT::getModuleBaseURL() + "tutorialservice"
		return tutorialService
	}
	
	def static getConfigService() {
		val ConfigurationServiceAsync configService = GWT::create(typeof(ConfigurationService))
		val endpoint = configService as ServiceDefTarget
		endpoint.serviceEntryPoint = GWT::getModuleBaseURL() + "configurationservice"
		return configService
	}
	
	def static getLoginService() {
		val LoginServiceAsync loginService = GWT::create(typeof(LoginService))
		val endpoint = loginService as ServiceDefTarget
		endpoint.serviceEntryPoint = GWT::getModuleBaseURL() + "loginservice"
		return loginService
	}
	
	def static DialogMessages getDialogMessages() {	
		return  GWT.create(DialogMessages)	
	}
}
