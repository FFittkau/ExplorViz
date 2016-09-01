ExpChart = function(canvas) {

	var data = {
		labels : [ "Interrupted", "Completed"],
		datasets : [ {
			data : [ 5, 10 ],
			backgroundColor : [ "#FF6384", "#12dc00" ],
			hoverBackgroundColor : [ "#FF6384", "#12dc00" ]
		} ]
	};

	var myPieChart = new Chart(canvas, {
		type : 'pie',
		data : data
		//options : options
	});

	// var myChart = new Chart(canvas, {
	// type: 'bar',
	// data: {
	// labels: ["Red", "Blue", "Yellow", "Green", "Purple", "Orange"],
	// datasets: [{
	// label: '# of Votes',
	// data: [12, 19, 3, 5, 2, 3],
	// backgroundColor: [
	// 'rgba(255, 99, 132, 0.2)',
	// 'rgba(54, 162, 235, 0.2)',
	// 'rgba(255, 206, 86, 0.2)',
	// 'rgba(75, 192, 192, 0.2)',
	// 'rgba(153, 102, 255, 0.2)',
	// 'rgba(255, 159, 64, 0.2)'
	// ],
	// borderColor: [
	// 'rgba(255,99,132,1)',
	// 'rgba(54, 162, 235, 1)',
	// 'rgba(255, 206, 86, 1)',
	// 'rgba(75, 192, 192, 1)',
	// 'rgba(153, 102, 255, 1)',
	// 'rgba(255, 159, 64, 1)'
	// ],
	// borderWidth: 1
	// }]
	// },
	// options: {
	// scales: {
	// yAxes: [{
	// ticks: {
	// beginAtZero:true
	// }
	// }]
	// }
	// }
	// });

}