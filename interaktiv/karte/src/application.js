'use strict';


import {maps} from './data';


require('./qvv.css');
require('./leaflet.fusesearch.09e7508.css');
require('./style.css');
require('leaflet-responsive-popup/leaflet.responsive.popup.css')
require('leaflet-gesture-handling/dist/leaflet-gesture-handling.css')



import {getEmbed} from './pymembed';
window.getEmbed = getEmbed;

import L from 'leaflet';
import URI from 'urijs';
import * as request from 'd3-request/index';
import * as format from 'd3-format/index';
import * as queue from 'd3-queue/index';
import * as scale from 'd3-scale/index';
import * as topojson  from 'topojson/index';
import './leaflet.fusesearch.09e7508';
import './leaflet.pattern.d543c9f';
import 'leaflet-responsive-popup';
import { GestureHandling } from "leaflet-gesture-handling";

import {legend} from './legend';

var PARAMS = URI.parseQuery(document.location.search)

var MAP = maps[PARAMS.map];

// set texts
document.getElementsByTagName('h1')[0].innerHTML = PARAMS.bundesland && MAP.bundesland_title ? MAP.bundesland_title : MAP.title;
document.querySelector('footer .actual_source').innerHTML = MAP.source;
document.querySelector('p.detail').innerHTML = MAP.detail || '';
document.querySelector('body p').innerHTML = MAP.description || '';




var colorlegend = legend[MAP.scale](MAP);
var pymChild = window.pym?new pym.Child():undefined;


format.formatDefaultLocale({decimal: ",", thousands: ".", grouping: [3], currency: ['€ ','']})
var numfmt = format.format(',d');
var pctfmt = format.format(',.1f');
var changefmt = (d) => (d>0?'+':'')+numfmt(d);
var changepctfmt = (d) => (d>0?'+':'')+pctfmt(d);

L.Map.addInitHook("addHandler", "gestureHandling", GestureHandling);
var map = L.map('graph',
  {
    zoomSnap: 0.25,
    gestureHandling: true,
    gestureHandlingOptions: {
        text: {
            touch: "Verwenden Sie zwei Finger, um die Karte zu zoomen.",
            scroll: "Verwenden Sie Ctrl + Scrollen, um die Karte zu zoomen.",
            scrollMac: "Verwenden Sie \u2318 + Scrollen, um die Karte zu zoomen."
        },
    }
  });

map.createPane('popup2',map._container);
map.on('move', function() {
  map._panes['popup2'].style.transform = map._mapPane.style.transform;

});


if(PARAMS.force_message || (PARAMS.bundesland && MAP.bundesland_message)) {
  document.querySelector('#bundesland_message').innerHTML = MAP.bundesland_message;
}

queue.queue()
  .defer(request.json, MAP.topojson || 'gemeinden m bezirke 2018.topojson')
  .defer(request[MAP.data.split('.').reverse()[0]], MAP.data)
  .await(function(error, topo, data){
    var os = topo.objects[Object.keys(topo.objects)[0]];
    if(PARAMS.bundesland) {
      os.geometries = os.geometries.filter((x) => x.properties.GKZ[0]==PARAMS.bundesland);
    }
    var tf =
      topojson.feature(topo, os);
    var layer;
    layer = L.geoJson(
      tf, {
        smoothFactor: L.Browser.retina?0.5:1,
        style: function(feature) {
          feature.data = data.filter((x) => (x.gkz||x.gkz_neu)==feature.properties.GKZ)[0];
          if(feature.data && !feature.properties.name && MAP.feature_name_override) {
              feature.properties.name = feature.data[MAP.feature_name_override];
          }
          var r = {
              color: 'white',
              weight: L.Browser.retina?0.25:0.5,
              opacity: 1,
              fillOpacity: 1
            };
          var fill = feature.data?colorlegend.getColor(feature.data):{fillColor: 'lightgrey'};
          for(var k of Object.keys(fill)) {
            if(k=='fillPattern') {
              fill[k].addTo(map);
            }
            r[k] = fill[k];
          }
          return r;
          },
        onEachFeature: function(feature,thislayer) {
          feature.layer = thislayer;
          thislayer.on({
            'mouseover': (e) => {e.target.setStyle({weight: 1.5})},
            'mouseout': (e) => {layer.resetStyle(e.target)}
          });


          var p = feature.properties;
          var d = feature.data;
          if(!d) {
            return;
          }
          thislayer.bindPopup(L.responsivePopup().setContent(
            MAP.tooltip(d,p,pctfmt,numfmt,changepctfmt,changefmt)
          ),{pane: 'popup2'});
        }
      });

    layer.addTo(map);
    var bm_key = (x) => PARAMS.bundesland?x.properties.GKZ.slice(0,3):x.properties.GKZ[0];
    var bm = topojson.mesh(topo,
      topo.objects[Object.keys(topo.objects)[0]],
        (a,b) => bm_key(a)!==bm_key(b)
    );

    var bm2 = topojson.mesh(topo,
      topojson.mergeArcs(topo,topo.objects[Object.keys(topo.objects)[0]].geometries.filter((d)=>d.properties.GKZ[0]=="9"))
    );

    var blayer = L.geoJson(
      [bm,bm2],
      {style: {fillColor: 'transparent',
        fillOpacity: 0, color: 'white', weight: 2, opacity: 1,
      attribution: 'Grenzen: cc-by Geoland.at, Wien.gv.at'}}
    );
    blayer.addTo(map);

    var searchCtrl = L.control.fuseSearch({maxResultLength: 6, placeholder: 'Gemeindesuche', title: 'Gemeindesuche'});
    searchCtrl.indexFeatures(tf,['name']);
    searchCtrl.addTo(map);
    document.getElementById('controls').appendChild(searchCtrl._container);
    searchCtrl._container.children[0].innerHTML='Gemeindesuche';

    document.querySelector('a.button').style.visibility=MAP.search===false?'hidden':'visible';

    var popup_highlight = null;
    var popup_line = null;

    map.on('popupopen', function(e) {
      var tooltip_elem = e.popup._container;
      console.log(e.popup);
      if(popup_highlight) {
        map.removeLayer(popup_highlight);
        popup_highlight=null;
      }
      if(popup_line) {
        map.removeLayer(popup_line);
        popup_line=null;
      }
      if(map._container.clientWidth<500) {
        tooltip_elem = document.getElementById('info');
        document.getElementById('info').innerHTML = e.popup._content;
        document.getElementById('info').style.maxHeight = 999+'px';
        map.closePopup();
        var t = map.containerPointToLatLng([map._size.x/2, 0]);
        popup_line = L.polyline([[e.popup._latlng.lat,e.popup._latlng.lng],
          t], {color: '#f1f1f1',weight: 2, opacity: 0.7}).addTo(map);
        document.querySelector('a.button').scrollIntoView()
        pymChild.scrollParentToChildPos(
          document.getElementById('info').getBoundingClientRect().top + window.pageYOffset - 125
        );
      } else {
        document.getElementById('info').innerHTML = '';
        document.getElementById('info').style.maxHeight = "0";
      }
      popup_highlight = L.geoJson(
        e.popup._source.feature.layer.toGeoJSON(),
        {style: {weight: 1.75, color: 'white', fillColor: 'transparent'}}).addTo(map);
        console.log(tooltip_elem);

      if(MAP.post_draw_tooltip) {
          console.log(tooltip_elem);
          MAP.post_draw_tooltip(tooltip_elem, pymChild, e.popup._source.feature, numfmt);
      }
      pymChild.sendHeight();
    });
    map.on('popupclose', function(e) {
      if(map._container.clientWidth<500){
        return;
      }
      if(popup_highlight) {
        map.removeLayer(popup_highlight);
      }
      if(popup_line) {
        map.removeLayer(popup_line);
      }
    });
    map.on('move', (e) => {
      if(popup_line) {
        map.removeLayer(popup_line);
        popup_line=null;
      }
    });


    map.zoomControl.setPosition('bottomright');

    colorlegend.addTo(map);

    var b = layer.getBounds()
    map.fitBounds(b, {
      paddingTopLeft: [0,60],
      paddingBottomRight: [0,25],
      animate: false
    });
    map.setMaxBounds(map.getBounds().pad(5));
    map.options.minZoom = map.getZoom()-0.5;
    map.fire('zoomend');

    pymChild.sendHeight();

    window.addEventListener('resize', function() {
      pymChild.sendHeight();
    })
});

if(PARAMS['3rdparty']!==undefined) {
    window.dataLayer = window.dataLayer || [];
    function gtag(){dataLayer.push(arguments);}
    gtag('js', new Date());

    gtag('config', 'UA-105776412-3');
}
