
var scanData;
var siteInfo;
var m_groups;
var m_savedScans="";

$('document').ready(function() {
	window.ruins = new function() {
	this.options = {
		panzoom: $(".panzoom"),
		zoomIn: $(".zoom-in"),
		zoomOut: $(".zoom-out"),
		zoomRange: $(".zoom-range"),
		reset: $(".reset")
	}

	this.panZoomComp = null;

	this.itemInteractionSelect = function(e){
		ruins.testLog(e.target.id);
		$(e.target).css('opacity',.1);
	}

	this.prepSVG = function(){
		var registerTouch = 0;
		//Mouse wheel zoom
		panZoomComp.parent().on('mousewheel.focal', function( e ) {
			e.preventDefault();
			var delta = e.delta || e.originalEvent.wheelDelta;
			var zoomOut = delta ? delta < 0 : e.originalEvent.deltaY > 0;
			panZoomComp.panzoom('zoom', zoomOut, {
				increment: 0.1,
				animate: false,
				focal: e
			});
		});

		//Mouse doublie click zoom
		panZoomComp.parent().on('dblclick', function( e ) {
			e.preventDefault();
			panZoomComp.panzoom('zoom', null, {
				increment: 10,
				animate: true,
				focal: e
			});
		});

		//Touch specific event handling
		$('.ruin-obelisk').on('mousedown touchstart',function(e){
			registerTouch = 1;
		});
		$('.ruin-obelisk').on('touchmove',function(e){
			registerTouch = 0;
		})
		$('.ruin-obelisk').on('touchend',function(e){
			if(registerTouch == 0){
				e.preventDefault();
					return;
				}
				registerTouch = 0;
				ruins.itemInteractionSelect(e);
			});

		//Click handlers
		$('.ruin-obelisk').on('click',function(e){
			ruins.itemInteractionSelect(e);
		});

		//Pointer to visualize that the item can be "clicked"
		$('.ruin-obelisk').css( 'cursor', 'pointer' );

		//Ensure that non interactive items don't interefere
		$('.ruin-inactive').css('pointer-events','none');

		//Hide Groups
		var alphabet = "abcdefghijklmnopqrstuvwxyz".split("");
		$.each(alphabet, function(letter) {
			//$('#ruin-number-' + alphabet[letter]).css('pointer-events','none');
			$('#ruin-number-' + alphabet[letter]).css('display','none');
		});
		this.testLog("Groups:"+m_groups);
		//Show Groups
		l_split_groups = m_groups.split("");
		$.each( l_split_groups, function(letter) {
			$('#ruin-number-' + l_split_groups[letter]).css('display','inline');
		});
	}

	this.setPanZoom = function(panZoomElement){
		panZoomComp = panZoomElement.panzoom({
			cursor: "-webkit-grab",
			minScale: .8,
			maxScale: 3,
			increment: .1,
			duration: 10,
			$zoomIn: ruins.options.zoomIn,
			$zoomOut: ruins.options.zoomOut,
			$zoomRange: ruins.options.zoomRange,
			$reset: ruins.options.reset,
			$set: panZoomElement
		});
	}

	this.changeRuinType = function(typeName,data){
		$.get("maps/"+typeName.toLowerCase()+".svg", function(data) {
			//Empty and then set the data
			$('#ruin-map').empty().append(data.documentElement);
			ruins.setPanZoom(ruins.options.panzoom);
			ruins.prepSVG();
		});
	}

	this.testLog = function(data){
		$('#templog').val($('#templog').val() + '\n' + data);
	}

	this.getScanData = function() {
		var xhttp1 = new XMLHttpRequest();
		var canonnUrl = "https://api.canonn.technology:8001/api/v1/maps/scandata"
		xhttp1.open("GET",canonnUrl,false);
		xhttp1.send(null);
		scanData = JSON.parse( xhttp1.responseText );
	
		canonnUrl = "https://api.canonn.technology:8001/api/v1/maps/systemoverview"
		xhttp1.open("GET",canonnUrl,false);
		xhttp1.send(null);
		siteInfo = JSON.parse( xhttp1.responseText );
	}

	this.setSite = function() {
		var xhttp1 = new XMLHttpRequest();
		var canonnUrl = "https://api.canonn.technology:8001/api/v1/maps/ruininfo/"+$("#site").val()
	
	// get the json data for the ruin site
		xhttp1.open("GET",canonnUrl,false);
		xhttp1.send(null);
		var ruinData = JSON.parse( xhttp1.responseText );
		$("#ruintype").html(ruinData.ruinTypeName);
		$("#location").html(ruinData.systemName+" / "+ruinData.bodyName+" "+ruinData.coordinates);
	
	// process active obelisks
		grps = ruinData.obelisks;
		m_groups = "";
		l_ruinType = ruinData.ruinTypeName.toLowerCase();
		var l_data = "";
		for(gkey in grps){
			obes = grps[ gkey ];
			m_groups=m_groups+gkey;
			for(okey in obes){
				if ( obes[okey] == 1 ) {
	//				console.log( gkey+okey );
						if ( okey < 10 ) {
							l_ob_name = gkey+"0"+okey;
						} else {
							l_ob_name = gkey+okey;
						}
						if ( scanData[l_ruinType][gkey][okey] ){
							l_ob_data = scanData[l_ruinType][gkey][okey].scan;
							l_scancode = l_ob_data.toLowerCase().substring(0,3);
							l_scancode = l_scancode+l_ob_data.toLowerCase().split(" ")[1];
							//this.testLog(l_scancode);
							l_ob_item1 = scanData[l_ruinType][gkey][okey].items[0];
							l_ob_item2 = scanData[l_ruinType][gkey][okey].items[1];
							if ( ! l_ob_item2 ) { l_ob_item2 = "-- "; }
							l_ob_items = l_ob_item1.substring(0,2)+"+"+l_ob_item2.substring(0,2);
							l_data=l_data+"<div class='"+l_scancode+" known'> "+l_ob_name+" "+l_ob_items+" = "+l_ob_data+"</div>";
						} else {
							l_data=l_data+"<div class='unknown'> "+l_ob_name+" : ??</div>";
						}
				}
			}
			l_data=l_data+"<hr>";
		}			
		$("#data").html(l_data);

		if ( ruinData.ruinTypeName != "Alpha" ) $("#GotAlpha").css('display','none');
		if ( ruinData.ruinTypeName != "Beta" )$("#GotBeta").css('display','none');
		if ( ruinData.ruinTypeName != "Gamma" ) $("#GotGamma").css('display','none');
		$("#Got"+ruinData.ruinTypeName).css('display','inline');

		// load SVG map
		this.changeRuinType(ruinData.ruinTypeName);
		this.processSave();
	}

	this.processSave = function() {
		// process the save data
		var l_debug="SaveItems:";
		this.testLog( "processSave:m_savedScans="+m_savedScans );
		l_savedScans = m_savedScans.split(",");
		$.each(l_savedScans, function(item) {
			l_gotScan=l_savedScans[item];
			if ( l_gotScan.length > 5 ) {
				$("#"+l_gotScan).prop('checked',true); 
				l_gotScan=l_gotScan.substring(3,8);
				l_debug=l_debug+l_gotScan+" ";
				$("."+l_gotScan).css({"text-decoration": "line-through","color": "SaddleBrown"});
			}
		});	
		this.testLog( l_debug );
	}
	
	this.saveGotScans = function() {
		this.testLog( "Save" );
		var l_saveData="";
		var l_savedScans = [];
		m_savedScans="SAVE,";
		$( "input" ).each(function( index ) {
			l_id=$( this ).attr('id');
			if ( l_id.substring(0,3) == "got" ) {
				if ( $( this ).prop('checked' ) ) {
					l_saveData=l_saveData+$( this ).attr('id')+"\n";
					m_savedScans=m_savedScans+$( this ).attr('id')+",";
					l_savedScans.push( $( this ).attr('id') );
				}
			}
		});
		this.testLog( "saveGotScans:m_savedScans="+m_savedScans );
		localStorage.setItem( 'gotScans',l_savedScans );
		this.testLog( l_saveData );
		this.processSave();
	}

	m_savedScans = localStorage.gotScans;
	if (!!m_savedScans) {
		this.testLog( "got save data" );
	} else {
		m_savedScans = "saved";
		this.testLog( "no save data" );
	}

	this.getScanData();
	this.setSite();	

	$("#hide").click(function(){
		$("#gotPanel").css('display','none');
		$("#hide").css('display','none');
		$("#show").css('display','inline');
 	});
	$("#show").click(function(){
		$("#gotPanel").css('display','inline');
		$("#hide").css('display','inline');
		$("#show").css('display','none');
 	});

	$("#save").click(function(){
		ruins.saveGotScans();
 	});

	$("#setSite").click(function(){
		ruins.setSite();
 	});

};
});
