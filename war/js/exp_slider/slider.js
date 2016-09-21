Slider = function(formHeight, save, landscapeNames, loadLandscape,
		jsonQuestionnaire, loadExperimentToolsPage, isWelcome) {

	var showExceptionDialog = false;

	var questionPointer = 0;

	var parsedQuestionnaire = JSON.parse(jsonQuestionnaire);
	if (!parsedQuestionnaire.questions[0]) {
		parsedQuestionnaire.questions.push({
			"answers" : [],
			"workingTime" : "",
			"type" : "",
			"expLandscape" : "",
			"questionText" : ""
		})
	}
	
	var AppState = can.Map.extend({
		questionnaire : parsedQuestionnaire,
		questionPointer : 0,
		currentQuestion : parsedQuestionnaire.questions[0]
	});
	
    var appState = new AppState();

	setupComponents();
	setupSliderStyle();

	function setupComponents() {
		
		can.Component.extend({
			tag : "slider-container",
			template : can.stache($('#slider_template').html()),
			viewModel : {
				showLandscapeInfo : landscapeNames.length > 0
			}
		});
		
		can.Component.extend({
			tag : "slider-no-landscape",
			template : can.stache($('#slider_no_landscape').html()),
		});

		can.Component
				.extend({
					tag : "slider-question",
					template : can.stache($('#slider_question').html()),
					init: function() {
						var self = this;
						
						this.viewModel.bind('state.currentQuestion', function() {
							
							self.viewModel.attr("questionType", appState.attr("currentQuestion.type"));

							if(appState.attr("currentQuestion.expLandscape") != "") {
								self.viewModel.attr("landscapeSelect", appState.attr("currentQuestion.expLandscape"));
							} else {
								var previousQuestionPointer = appState.attr("questionPointer") - 1;
								var previousQuestion = appState.attr("questionnaire.questions." + previousQuestionPointer);	
								self.viewModel.attr("landscapeSelect", previousQuestion.expLandscape);
							}							
							self.viewModel.loadExplorVizLandscape(self.viewModel);							
						});										
						
						if(appState.attr("currentQuestion.expLandscape"))
							self.viewModel.attr("landscapeSelect", appState.attr("currentQuestion.expLandscape"));
						
						var answers = appState.attr("currentQuestion.answers");
						var length = answers.length;
						
						if(length > 0 && answers[length-1] != "") {
							
							// add one empty answer for new input
							var answers = appState.attr("currentQuestion.answers");
							
							answers.push({
			                    "answerText": "",
			                    "checkboxChecked": false
			                });					
			
							appState.attr("currentQuestion.answers", answers);								
						}
						
						this.viewModel.loadExplorVizLandscape(this.viewModel);
					},
					viewModel : {
						state: appState,
						landscapeNames : landscapeNames,
						loadExplorVizLandscape : function(viewModel) {
							
							loadLandscape(viewModel.attr("landscapeSelect"));							
							showExceptionDialog = false;
							
					}
				}				
		});

		can.Component.extend({
			tag : "slider-question-free",
			template : can.stache($('#slider_question_free').html()),
			viewModel : {
				state: appState
			},
			events: {
				'.answerInput:last keydown': function() {
					var answers = this.viewModel.attr('state.currentQuestion.answers')
					answers.push({ 
						answerText: "", 
						checkboxChecked: false
						})
				}
			}
		});
		
		can.Component.extend({
			tag : "slider-question-mc",
			template : can.stache($('#slider_question_multiple_choice').html()),
			viewModel : {
				state: appState
			},
				events: {
					'.answerInput:last keydown': function() {
						var answers = this.viewModel.attr('state.currentQuestion.answers')
						answers.push({ 
							answerText: "", 
							checkboxChecked: false
							});
					}
				}
		});

		can.Component.extend({
			tag : "slider-buttons",
			template : can.stache($('#slider_buttons').html()),
			viewModel : {
				showDelete : appState.attr("currentQuestion.answers").length > 0
			},
			events : {
				"#exp_slider_question_nextButton click" : function() {
					var form = document.getElementById("exp_slider_question_form");		
					
					if(isFormCompleted(form)) {
						var jsonForm = formValuesToJSON(form);			
						
						can.batch.start();
						
						appState.attr("questionnaire.questions." + appState.attr("questionPointer"), jsonForm);
						sendCompletedData(appState.attr("questionnaire").serialize());
						
						appState.attr("questionPointer", appState.attr("questionPointer") + 1);							
						appState.attr("currentQuestion", appState.attr("questionnaire.questions." + appState.attr("questionPointer")));
													
						if(!appState.attr("currentQuestion")) {
							appState.attr("questionnaire.questions." + appState.attr("questionPointer") , {
								"answers" : [],
								"workingTime" : "",
								"type" : "freeText",
								"expLandscape" : "",
								"questionText" : ""
							}); 
							appState.attr("currentQuestion", appState.attr("questionnaire.questions." + appState.attr("questionPointer")));
							this.viewModel.attr("showDelete", false);
						} else {							
							
							if(appState.attr("currentQuestion.questionText").length == 0) {
								this.viewModel.attr("showDelete", false);
							} else {
								this.viewModel.attr("showDelete", true);
							}
							
							var answers = appState.attr("currentQuestion.answers");
							var length = answers.length;
							
							if(answers[length-1] != "") {
								
								// add one empty answer for new input
								var answers = appState.attr("currentQuestion.answers");
								
								answers.push({
				                    "answerText": "",
				                    "checkboxChecked": false
				                });					
				
								appState.attr("currentQuestion.answers", answers);								
							}
						}						
					}
					else {
						swal({
							title : "Insert all data!",
							text : "Not all necessary data is completed.",
							type : "warning",
							showCancelButton : false,
							confirmButtonColor : "#8cd4f5",
							confirmButtonText : "I understand.",
							closeOnConfirm : true
						});								
					}
					can.batch.stop();
				},
				"#exp_slider_question_saveButton click" : function() {
					sendCompletedData(appState.attr("questionnaire").serialize());
					loadExperimentToolsPage();
				},
				"#exp_slider_question_backButton click" : function() {
					var form = document
					.getElementById("exp_slider_question_form");
					var jsonForm = formValuesToJSON(form);
					
					can.batch.start();
					appState.attr("questionnaire.questions." + appState.attr("questionPointer"), jsonForm);
					
					if (appState.attr("questionPointer") > 0) {
						
						appState.attr("questionPointer", appState.attr("questionPointer") - 1);
						appState.attr("currentQuestion", appState.attr("questionnaire.questions." + appState.attr("questionPointer")));						
					
						// add one empty answer for new input
						var answers = appState.attr("currentQuestion.answers");
						
						answers.push({
		                    "answerText": "",
		                    "checkboxChecked": false
		                });					
		
						appState.attr("currentQuestion.answers", answers);
					
					}
					
					if(!appState.attr("currentQuestion")) {
						this.viewModel.attr("showDelete", false);
					} 
					else {
						if(appState.attr("currentQuestion.questionText").length > 0)
							this.viewModel.attr("showDelete", true);
					}
					
					can.batch.stop();
				},
				"#exp_slider_question_removeButton click" : function() {
					can.batch.start();
					
					var questions = appState.attr("questionnaire.questions");					
					questions.splice(appState.attr("questionPointer"), 1);
					appState.attr("questionnaire.questions", questions);
					
					appState.attr("currentQuestion", appState.attr("questionnaire.questions." + appState.attr("questionPointer")));
					
					if(!appState.attr("currentQuestion")) {
						this.viewModel.attr("showDelete", false);
					} 
					else {						
						
						if(appState.attr("currentQuestion.questionText").length == 0) {
							this.viewModel.attr("showDelete", false);
						} else {
							this.viewModel.attr("showDelete", true);
						}						
					}
					
					can.batch.stop();	
					
					sendCompletedData(appState.attr("questionnaire").serialize());
				}
			}
		});
		
		can.Component.extend({
			tag : "slider-error-input",
			template : can.stache($('#slider_error_input').html()),
		});		

		var template = can.stache("<slider-container></slider-container>");
		$('#view').append(template());

	}

	function setupSliderStyle() {
		$('#expSliderInnerContainer').height(formHeight);
		$('#expQuestionForm').css('maxHeight', formHeight - 70);
		
		$('#expScrollable').height(formHeight);
		$('#expScrollable').css('maxHeight', formHeight - 35);
		
		$('#expSlider').css('right', 0);
		$('#expSliderLabel').click(function(e) {
			e.preventDefault();
			toggle[c++ % 2]();
		});
		// Setup toggle mechanism
		var toggle = [ slideOut, slideIn ], c = 1;

		function slideOut() {
			var right = -315;

			function slideOutFrame() {
				right += 5;
				expSlider.style.right = right + 'px';
				if (right == 0)
					clearInterval(id);
			}
			var id = setInterval(slideOutFrame, 7);
		}

		function slideIn() {
			var right = 0;

			function slideInFrame() {
				right -= 5;
				expSlider.style.right = right + 'px';
				if (right == -315)
					clearInterval(id);
			}
			var id = setInterval(slideInFrame, 7);
		}
	}

	function sendCompletedData(questionnaire) {
		// filter for well-formed questions
		var wellFormedQuestions = questionnaire.questions.filter(function(
				elem, index, obj) {		
			
			var hasAnswer = elem.answers[0] != "";

			var hasText = elem.questionText.length > 0;
			var hasWorkingTime = elem.workingTime.length > 0;

			return hasAnswer && hasText && hasWorkingTime;
		});
		
		var wellFormQuestionnaire = JSON.parse(JSON.stringify(questionnaire));
		wellFormQuestionnaire.questions = wellFormedQuestions;

		// send to server
		save(JSON.stringify(wellFormQuestionnaire));
	}
//	
//	function updateAnswerFields(){
//		if(appState.attr("currentQuestion.answers").length == 1){
//			if(appState.attr("currentQuestion.answers.0").length>= 1){
//				appState.attr("currentQuestion.answers.1", { "answerText": "", "checkboxChecked": false});
//			}
//		}
//	}

	var isFormCompleted = function(expQuestionForm) {

		var elements = expQuestionForm.elements;

		// check if at least one answer is set
		var answerInputs = Array.prototype.slice.call(document.getElementById(
				"answers").querySelectorAll('[id^=answerInput]'));

		var answerCheckboxes = Array.prototype.slice.call(document
				.getElementById("answers").querySelectorAll(
						'[id^=answerCheckbox]'));

		var atLeastOneAnswer = answerInputs.filter(function(answer) {
			if (answer.value != "")
				return true;
		}).length > 0 ? true : false;

		// check if inputs before answers are all filled
		var upperBound = elements.length
				- (answerInputs.length + answerCheckboxes.length);

		for (var i = 0; i < upperBound; i++) {
			if (elements[i].value == "") {
				return false;
			}
		}
		return atLeastOneAnswer;
	}

	var createProperty = function(obj, key, value) {
		var config = {
			value : value,
			writable : true,
			enumerable : true,
			configurable : true
		};
		Object.defineProperty(obj, key, config);
	};

	function formValuesToJSON(expQuestionForm) {

		var container = {};

		var obj = {};

		obj["type"] = "";
		obj["questionText"] = "";
		obj["workingTime"] = "";
		obj["answers"] = [];

		var elements = expQuestionForm.elements;
		var length = elements.length - 1;

		var answers = [];

		// add ExplorViz landscape identifier
		createProperty(obj, "expLandscape", $(
				'#exp_slider_question_landscape option:selected').val());

		// add type
		createProperty(obj, "type", $(
				'#exp_slider_question_questiontype option:selected').val());

		var answerCounter = 0;

		// rename answer ids due to possible empty inputs
		// and create json
		for (var i = 0; i < length; i++) {

			if (elements[i].value != "") {

				if (elements[i].id.indexOf("answerInput") == 0) {

					if (answers.length == 0) {
						createProperty(obj, "answers", answers);
					}

					var answer = {};

					var checked = elements[("answerCheckbox" + answerCounter)].checked;

					createProperty(answer, "answerText",
							elements[i].value.toString());
					
					createProperty(answer, "checkboxChecked",
							checked);

					answers.push(answer);

					answerCounter++;

				} else if (elements[i].id.indexOf("answerCheckbox") != 0) {

					createProperty(obj, elements[i].id.toString(),
							elements[i].value);

				}
			}

			else if (elements[i].id.indexOf("answerInput") == 0) {

				answerCounter++;

			}
		}

		if (answers.length == 0) {
			createProperty(obj, "answers", answers);
			answers.push("");
		}
		
		console.log("before", answers);
		
		// empty answer input
//		answers.push({
//            "answerText": "",
//            "checkboxChecked": false
//        });
//		
		console.log("after", answers);

		return obj;
	}

	function loadExplorViz() {
		if (qtLandscape.options[qtLandscape.selectedIndex] == undefined) {
			showExceptionDialog = true;
		} else {
			loadLandscape(qtLandscape.options[qtLandscape.selectedIndex].innerHTML);
			showExceptionDialog = false;
		}

	}
}