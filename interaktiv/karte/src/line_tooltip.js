import * as d3 from 'd3-jetpack/build/d3v4+jetpack';

export function tooltip_render(margin,svg,container,tooltip,a,
    xScale,xValue,yScale,yValue,rscale,width,height,
    callback,hide_title) {

    if(a) {
      var x = xScale(xValue(a));
      var y = yScale.clamp(true)(yValue(a));
      var r = rscale(a.radius);
      if(x>width/2) {
        var xpos = margin.right+width-x+r;
        var xtype = 'right';
      } else {
        var xpos = x+r+margin.left;
        var xtype = 'left';
      }
      if(y>height/2) {
        var ytype = 'bottom';
        var ypos = height-y+margin.bottom+r;
      } else {
        var ytype = 'top';
        var ypos = y+margin.top+r;
      }
      var d = {};
      d['top']=d['bottom']=d['left']=d['right']='auto';
      d[xtype]=xpos;
      d[ytype]=ypos;
      d['text-align']=xtype;
      d.opacity=1;
      d.display='block';
      tooltip.st(d)
      tooltip.html(!hide_title?`<strong>${a.label}</strong><br />
                    ${a.text}
        `:`${a.text}`);
        if(callback) {
          callback(a);
        }
    } else {
      tooltip.st({opacity: 0, display: 'none'})
        if(callback) {
          callback(null);
        }
    }
}

export function tooltip_update(margin,svg,container,tooltip,data,
            xScale,xValue,yScale,yValue,rscale,width,height,
            callback) {
    var xy = d3.mouse(container.node());
    xy[0]-=margin.left;
    xy[1]-=margin.top;
    var enclosed = data.filter(
      (d) => {
          var cx = xScale(xValue(d));
          var cy = yScale(yValue(d));
          var r = rscale(d.radius);
          var px = xy[0]*1.0;
          var py = xy[1]*1.0;
          var xdist = Math.pow(px*1.0-cx,2);
          var ydist = Math.pow(py*1.0-cy,2);
          var t = Math.pow(r,2);
          return xdist+ydist < t;
      })
    enclosed.sort((a,b) => b-a);
    if(enclosed.length>0) {
      var a = enclosed.slice(-1)[0];
    }

    if(!a) {
      var v = d3.voronoi().x((d) => xScale(xValue(d)))
        .y((d) => yScale(yValue(d)))(data);
      a = v.find(xy[0],xy[1],Math.max(width/8,40));
      if(a) {
        a = data[a.index];
      }
    }

    svg.selectAll('circle.dot').classed('hover', (d) => {
      return d==a?true:false;
    });

    return tooltip_render(margin,svg,container,tooltip,a,xScale,xValue,yScale,yValue,rscale,width,height,callback);
};
