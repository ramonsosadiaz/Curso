<!DOCTYPE html>
<meta charset="utf-8">
<style>
body{
    width:1060px;
    margin:50px auto;
}
path {  stroke: #fff; }
path:hover {  opacity:0.9; }
rect:hover {  fill:blue; }
.axis {  font: 10px sans-serif; }
.legend tr{    border-bottom:1px solid grey; }
.legend tr:first-child{    border-top:1px solid grey; }

.axis path,
.axis line {
  fill: none;
  stroke: #000;
  shape-rendering: crispEdges;
}

.x.axis path {  display: none; }
.legend{
    margin-bottom:76px;
    display:inline-block;
    border-collapse: collapse;
    border-spacing: 0px;
}
.legend td{
    padding:4px 5px;
    vertical-align:bottom;
}
.legendfreq, .legendPerc{
    align:right;
    width:50px;
}

</style>
<body>
<div>
	<input type="button" onclick="ajax()" value="Actualizar"></input>
</div>
<div id='dashboard'>
</div>
<script src="http://d3js.org/d3.v3.min.js"></script>
<script>
function dashboard(id, fData){
    var barColor = 'steelblue';
    function segColor(c){ return {Aceptados:"#41ab5d", Rechazados:"red",Pendientes:"orange",NoAceptados:"yellow"}[c]; }
    
    // compute total for each State.
    fData.forEach(function(d){d.total=Number(d.freq.Aceptados)+Number(d.freq.Rechazados)+Number(d.freq.Pendientes)+Number(d.freq.NoAceptados);});
    
    // function to handle histogram.
    function histoGram(fD){
        var hG={},    hGDim = {t: 60, r: 0, b: 30, l: 0};
        hGDim.w = 500 - hGDim.l - hGDim.r, 
        hGDim.h = 300 - hGDim.t - hGDim.b;
            
        //create svg for histogram.
        var hGsvg = d3.select(id).append("svg")
            .attr("width", hGDim.w + hGDim.l + hGDim.r)
            .attr("height", hGDim.h + hGDim.t + hGDim.b).append("g")
            .attr("transform", "translate(" + hGDim.l + "," + hGDim.t + ")");

        // create function for x-axis mapping.
        var x = d3.scale.ordinal().rangeRoundBands([0, hGDim.w], 0.1)
                .domain(fD.map(function(d) { return d[0]; }));

        // Add x-axis to the histogram svg.
        hGsvg.append("g").attr("class", "x axis")
            .attr("transform", "translate(0," + hGDim.h + ")")
            .call(d3.svg.axis().scale(x).orient("bottom"));

        // Create function for y-axis map.
        var y = d3.scale.linear().range([hGDim.h, 0])
                .domain([0, d3.max(fD, function(d) { return d[1]; })]);

        // Create bars for histogram to contain rectangles and freq labels.
        var bars = hGsvg.selectAll(".bar").data(fD).enter()
                .append("g").attr("class", "bar");
        
        //create the rectangles.
        bars.append("rect")
            .attr("x", function(d) { return x(d[0]); })
            .attr("y", function(d) { return y(d[1]); })
            .attr("width", x.rangeBand())
            .attr("height", function(d) { return hGDim.h - y(d[1]); })
            .attr('fill',barColor)
            .on("mouseover",mouseover)// mouseover is defined beAceptados.
            .on("mouseout",mouseout);// mouseout is defined beAceptados.
            
        //Create the frequency labels above the rectangles.
        bars.append("text").text(function(d){ return d3.format(",")(d[1])})
            .attr("x", function(d) { return x(d[0])+x.rangeBand()/2; })
            .attr("y", function(d) { return y(d[1])-5; })
            .attr("text-anchor", "Rechazadosdle");
        
        function mouseover(d){  // utility function to be called on mouseover.
            // filter for selected State.
            var st = fData.filter(function(s){ return s.State == d[0];})[0],
                nD = d3.keys(st.freq).map(function(s){ return {type:s, freq:st.freq[s]};});
               
            // call update functions of pie-chart and legend.    
            pC.update(nD);
            leg.update(nD);
        }
        
        function mouseout(d){    // utility function to be called on mouseout.
            // reset the pie-chart and legend.    
            pC.update(tF);
            leg.update(tF);
        }
        
        // create function to update the bars. This will be used by pie-chart.
        hG.update = function(nD, color){
            // update the domain of the y-axis map to reflect change in frequencies.
            y.domain([0, d3.max(nD, function(d) { return d[1]; })]);
            
            // Attach the new data to the bars.
            var bars = hGsvg.selectAll(".bar").data(nD);
            
            // transition the height and color of rectangles.
            bars.select("rect").transition().duration(500)
                .attr("y", function(d) {return y(d[1]); })
                .attr("height", function(d) { return hGDim.h - y(d[1]); })
                .attr("fill", color);

            // transition the frequency labels location and change value.
            bars.select("text").transition().duration(500)
                .text(function(d){ return d3.format(",")(d[1])})
                .attr("y", function(d) {return y(d[1])-5; });            
        }        
        return hG;
    }
    
    // function to handle pieChart.
    function pieChart(pD){
        var pC ={},    pieDim ={w:250, h: 250};
        pieDim.r = Math.min(pieDim.w, pieDim.h) / 2;
                
        // create svg for pie chart.
        var piesvg = d3.select(id).append("svg")
            .attr("width", pieDim.w).attr("height", pieDim.h).append("g")
            .attr("transform", "translate("+pieDim.w/2+","+pieDim.h/2+")");
        
        // create function to draw the arcs of the pie slices.
        var arc = d3.svg.arc().outerRadius(pieDim.r - 10).innerRadius(0);

        // create a function to compute the pie slice angles.
        var pie = d3.layout.pie().sort(null).value(function(d) { return d.freq; });

        // Draw the pie slices.
        piesvg.selectAll("path").data(pie(pD)).enter().append("path").attr("d", arc)
            .each(function(d) { this._current = d; })
            .style("fill", function(d) { return segColor(d.data.type); })
            .on("mouseover",mouseover).on("mouseout",mouseout);

        // create function to update pie-chart. This will be used by histogram.
        pC.update = function(nD){
            piesvg.selectAll("path").data(pie(nD)).transition().duration(500)
                .attrTween("d", arcTween);
        }        
        // Utility function to be called on mouseover a pie slice.
        function mouseover(d){
            // call the update function of histogram with new data.
            hG.update(fData.map(function(v){ 
                return [v.State,v.freq[d.data.type]];}),segColor(d.data.type));
        }
        //Utility function to be called on mouseout a pie slice.
        function mouseout(d){
            // call the update function of histogram with all data.
            hG.update(fData.map(function(v){
                return [v.State,v.total];}), barColor);
        }
        // Animating the pie-slice requiring a custom function which specifies
        // how the intermediate paths should be drawn.
        function arcTween(a) {
            var i = d3.interpolate(this._current, a);
            this._current = i(0);
            return function(t) { return arc(i(t));    };
        }    
        return pC;
    }
    
    // function to handle legend.
    function legend(lD){
        var leg = {};
            
        // create table for legend.
        var legend = d3.select(id).append("table").attr('class','legend');
        
        // create one row per segment.
        var tr = legend.append("tbody").selectAll("tr").data(lD).enter().append("tr");
            
        // create the first column for each segment.
        tr.append("td").append("svg").attr("width", '16').attr("height", '16').append("rect")
            .attr("width", '16').attr("height", '16')
			.attr("fill",function(d){ return segColor(d.type); });
            
        // create the second column for each segment.
        tr.append("td").text(function(d){ return d.type;});

        // create the third column for each segment.
        tr.append("td").attr("class",'legendfreq')
            .text(function(d){ return d3.format(",")(d.freq);});

        // create the fourth column for each segment.
        tr.append("td").attr("class",'legendPerc')
            .text(function(d){ return getLegend(d,lD);});

        // Utility function to be used to update the legend.
        leg.update = function(nD){
            // update the data attached to the row elements.
            var l = legend.select("tbody").selectAll("tr").data(nD);

            // update the frequencies.
            l.select(".legendfreq").text(function(d){ return d3.format(",")(d.freq);});

            // update the percentage column.
            l.select(".legendPerc").text(function(d){ return getLegend(d,nD);});        
        }
        
        function getLegend(d,aD){ // Utility function to compute percentage.
            return d3.format("%")(d.freq/d3.sum(aD.map(function(v){ return v.freq; })));
        }

        return leg;
    }
    
    // calculate total frequency by segment for all State.
    var tF = ['Aceptados','Rechazados','Pendientes','NoAceptados'].map(function(d){ 
        return {type:d, freq: d3.sum(fData.map(function(t){ return t.freq[d];}))}; 
    });    
    
    // calculate total frequency by State for all segment.
    var sF = fData.map(function(d){return [d.State,d.total];});

    var hG = histoGram(sF), // create the histogram.
        pC = pieChart(tF), // create the pie-chart.
        leg= legend(tF);  // create the legend.
}
</script>
<script src="js/jquery-1.11.1.min.js"></script>
<script type="text/javascript" >
/*  var freqData=[
{State:'RA',freq:{Aceptados:4786, Rechazados:1319, Pendientes:249}}
,{State:'AZ',freq:{Aceptados:1101, Rechazados:412, Pendientes:674}}
,{State:'CT',freq:{Aceptados:932, Rechazados:2149, Pendientes:418}}
,{State:'DE',freq:{Aceptados:832, Rechazados:1152, Pendientes:1862}}
,{State:'FL',freq:{Aceptados:4481, Rechazados:3304, Pendientes:948}}
,{State:'GA',freq:{Aceptados:1619, Rechazados:167, Pendientes:1063}}
,{State:'IA',freq:{Aceptados:1819, Rechazados:247, Pendientes:1203}}
,{State:'IL',freq:{Aceptados:4498, Rechazados:3852, Pendientes:942}}
,{State:'IN',freq:{Aceptados:797, Rechazados:1849, Pendientes:1534}}
,{State:'KS',freq:{Aceptados:162, Rechazados:379, Pendientes:471}}
]; */

function ajax(){
  $.ajax({
          	async: true,
            type: "POST",
            //url: "http://localhost/Graficos/graficos.cfc?method=grafico",
            url: "http://localhost/Eventos/Eventos.cfc?method=grafico",
            //data: "&cod_evento=" + id + '&fecha=' + fecha + "&descripcion=" + descripcion,
            //data: "&nombre="+ encodeURIComponent($("#txtNombre").val()) + '&sexo=' + $("#ddlSexo").val(), //+ $("#ddlSexo").children('option:selected').data('label'),
            dataType: "json",
            success: function(data) {
         
          // var g = JSON.parse(data.data);
         
            var p2 = eval(data);
          //  console.log(p2);
           //console.log(JSON.parse(JSON.stringify(data)));
           console.log(p2);
            $("#dashboard").html('');
          
           dashboard('#dashboard',p2);
           
           
            },
            timeout: 240000,
            error: function(e,data) {
          
                       
              console.log(data);
            }            
        
        });	
};		
/*var freqData=[
{State:'RA',freq:{Aceptados:4786, Rechazados:1319, Pendientes:249}}
,{State:'AZ',freq:{Aceptados:1101, Rechazados:412, Pendientes:674}}
,{State:'CT',freq:{Aceptados:932, Rechazados:2149, Pendientes:418}}
,{State:'DE',freq:{Aceptados:832, Rechazados:1152, Pendientes:1862}}
,{State:'FL',freq:{Aceptados:4481, Rechazados:3304, Pendientes:948}}
,{State:'GA',freq:{Aceptados:1619, Rechazados:167, Pendientes:1063}}
,{State:'IA',freq:{Aceptados:1819, Rechazados:247, Pendientes:1203}}
,{State:'IL',freq:{Aceptados:4498, Rechazados:3852, Pendientes:942}}
,{State:'IN',freq:{Aceptados:797, Rechazados:1849, Pendientes:1534}}
,{State:'KS',freq:{Aceptados:162, Rechazados:379, Pendientes:471}}
];*/


</script>