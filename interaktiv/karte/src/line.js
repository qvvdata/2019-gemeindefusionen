//import * as d3 from 'd3';
import * as d3 from 'd3-jetpack/build/d3v4+jetpack';
import {tooltip_update,tooltip_render} from './line_tooltip';

export function redraw(data, container, settings, first) {
  var time = first?0:1000;

  settings = settings || {};
  settings.xlabel = settings.xlabel || '';
  settings.ylabel = settings.ylabel || '';
  var margin = {top: 0, right: 20, bottom: 24, left: 30};

  var width = container.node().clientWidth - margin.left - margin.right;
  var height = 125 - margin.top - margin.bottom;

  var all_datapoints = [];
  data.map((x) => {all_datapoints = all_datapoints.concat(x)});



  // setup x
  var xValue = (d) => { return d.xvalue;}, // data -> value
      xScale = d3.scaleLinear().range([0, width]), // value -> display
      xMap = (d) => { return xScale(xValue(d));}, // data -> display
      xAxis = d3.axisBottom().scale(xScale).ticks(8);

  if(settings.xfmt) {
    xAxis.tickFormat(settings.xfmt);
  }

  // setup y
  var yValue = (d) => { return d["yvalue"];}, // data -> value
      yScale = d3.scaleLinear().range([height, 0]), // value -> display
      yMap = (d) => { return yScale(yValue(d));}, // data -> display
      yAxis = d3.axisLeft().scale(yScale).ticks(3);

  if(settings.yfmt) {
    yAxis.tickFormat(settings.yfmt);
  }

  // add the graph canvas to the body of the webpage
  var svg = container.selectAppend("svg.linechart")
      .attr("width", width + margin.left + margin.right)
      .attr("height", height + margin.top + margin.bottom)
    .selectAppend("g")
      .attr("transform", "translate(" + margin.left + "," + margin.top + ")");
  svg.selectAppend('rect')
    .at({x: 0,y: 0, width: width, height: height, fill: 'transparent', stroke: 'transparent'})

  // add the tooltip area to the webpage
  var tooltip_active_start = container
      .selectAppend("div.tooltip.tts")
      .style("opacity", 0);
  var tooltip_active_end = container
      .selectAppend("div.tooltip.tte")
      .style("opacity", 0);
  // add the tooltip area to the webpage
  var tooltip = container
      .selectAppend("div.tooltip.proper")
      .style("opacity", 0);

  // don't want dots overlapping axis, so add in buffer to data domain
  xScale.domain([d3.min(all_datapoints, xValue), d3.max(all_datapoints, xValue)]);

  var all_yvalues = all_datapoints.map(yValue);
  all_yvalues.sort((a,b) => a-b);

  var max = all_yvalues[all_yvalues.length-1];
  var second = all_yvalues[all_yvalues.length-2];

  yScale.domain([0, max>second*2?second*1.1:max]);

  // x-axis
  svg.selectAppend("g.x.axis")
    .transition()
      .duration(time)
      .attr("transform", "translate(0," + height + ")")
      .call(xAxis)
    .selectAll('text')
      .attr('transform', width<500?'rotate(45)':'')
      .attr('text-anchor', width<500?'start':'')
      .attr('dx',width<500?'0.2em':null)
      .attr('dy',width<500?'0.2em':'0.71em');
  svg.selectAppend("g.x.axis")
    .selectAppend("text.label_2")
      .transition()
      .duration(time)
      .attr("x", xScale(0)+5)
      .attr("y", -6)
      .style("text-anchor", "start")
      .text(settings.xlabel[1]);
  svg.selectAppend("g.x.axis")
    .selectAppend("text.label_1")
      .transition()
      .duration(time)
      .attr("x", xScale(0)-5)
      .attr("y", -6)
      .style("text-anchor", "end")
      .text(settings.xlabel[0]);

  // y-axis
  svg.selectAppend("g.y.axis")
    .transition()
      .duration(time)
      .call(yAxis)
  svg.selectAppend("g.y.axis")
    .selectAppend("text.label")
      .attr("transform", "rotate(-90)")
      .attr("y", 6)
      .attr("dy", ".71em")
      .style("text-anchor", "end")
      .text(settings.ylabel);


  svg.selectAppend('path.xzero')
    .transition()
      .duration(time)
    .attr('d', d3.line()(([[xScale(0)+0.5,yScale.range()[0]],[xScale(0)+0.5,yScale.range()[1]]])));
  svg.selectAppend('path.yzero')
    .transition()
      .duration(time)
    .attr('d', d3.line()(([[xScale.range()[0],yScale(0)+0.5],[xScale.range()[1],yScale(0)+0.5]])));

  // draw dots
  var dots = svg.selectAll(".dot")
      .data(all_datapoints.filter((d) => !isNaN(yValue(d))),
      (d) => xValue(d) + d.title)
  dots
    .enter().append("circle")
    .merge(dots)
      .attr("class", (d) => `dot ${d.title}`)
      .transition()
      .duration(time)
      .attr('opacity', 0)
      .attr("r", (d) => 1.5)
      .attr("cx", xMap)
      .attr("cy", yMap);
  dots.exit().remove();

  var dots = svg.selectAll(".dot")
      .data(all_datapoints.filter((d) => !isNaN(xValue(d))),
      (d) => xValue(d) + d.title)
  dots.exit().remove();

  var path = d3.line()
    .x((x) => xScale(xValue(x)))
    .y((x) => yScale(yValue(x)));

  var lines = svg.selectAll(".line")
      .data(data, (d) => d[0].title)
  lines.exit().remove();
  lines
    .enter().append("path")
    .merge(lines)
      .attr("class", (d) => `line ${d[0].title}`)
      .sort()
      .transition()
      .duration(time)
      .attr("d", path);

  var check_overlap = function(e1,e2) {
    try {
      var rect1 = e1.getBoundingClientRect();
      var rect2 = e2.getBoundingClientRect();
      var overlap = !(rect1.right < rect2.left ||
                  rect1.left > rect2.right ||
                  rect1.bottom < rect2.top ||
                  rect1.top > rect2.bottom);

      return overlap;
    } catch(e) {
      return false;
    }
  }

  var update_highlight = function() {
    data.sort(function(a,b) { return (a[0].active||a[0].highlight)?1:((b[0].active||b[0].highlight)?-1:0); });
    var lines = svg.selectAll(".line")
      .data(data, (d) => d[0].title)
      .sort()
    lines.classed('active', (d) => d[0].active).classed('highlight', (d) => d[0].highlight);
    var tl = data.filter((x) => x[0].active)[0];
    tooltip_render(margin, svg, container, tooltip_active_start, tl[0],
      xScale,xValue,yScale,yValue,(x) => 5,width,height);
    tooltip_render(margin, svg, container, tooltip_active_end, tl[tl.length-1],
      xScale,xValue,yScale,yValue,(x) => 5,width,height, null, true);
    if(check_overlap(tooltip.node(), tooltip_active_start.node())) {
      tooltip_active_start.style('opacity', 0);
    }
    if(check_overlap(tooltip.node(), tooltip_active_end.node())) {
      tooltip_active_end.style('opacity', 0);
    }
  }


  var set_highlight = function(point) {
    data.map((l) => l.map((p) => p.highlight = l.indexOf(point)>=0));
    update_highlight();
  }
  set_highlight(null);


  var ttu = tooltip_update.bind(this,margin,svg,container,tooltip,all_datapoints,xScale,xValue,yScale,yValue,(x) => 5,width,height,
    set_highlight);
  svg.on('mousemove', ttu);
  svg.on('click', ttu);
}
export default redraw;
