import L from 'leaflet';
import * as d3scale from 'd3-scale';


var legend = {};

legend['manual-bivariate'] = function(MAP) {
    var legend = L.control({position: 'topleft'});

    legend.onAdd = function (map) {
        var div = L.DomUtil.create('div', 'info legend multivariate');

        // loop through the status values and generate a label with a coloured square for each value
        div.innerHTML = `<p class="title">&nbsp;${MAP.value[0]}</p>`+ MAP.order[1].map(
        (x,i) => {
            return MAP.order[0].map((y,j) => {
                return `<span style="background: ${MAP.colorschemes[j][i]}"></span>`;
            }).join('')+` ${MAP.order[0][i]}`;
        }).join('<br />') + '<br />⟶&#xfe0e; ' + MAP.value[1];
        return div;
    };


    legend.getColor = function(data) {
        var v1 = MAP.order[0].indexOf(data[MAP.value[0]]);
        var v2 = MAP.order[1].indexOf(data[MAP.value[1]]);

        return MAP.colorschemes[v2][
              v1
              ];
    };

    return legend;
};
legend['category-multi'] = function(MAP) {
    var legend = L.control({position: 'topleft'});
    var scale = d3scale.scaleOrdinal(MAP.colorschemes[0]);
    if(MAP.categories) {
        scale = scale.domain(MAP.categories);
    }
    var patterns = {};

    legend.onAdd = function (map) {
        if(MAP.categories) {
            for(var e of document.querySelectorAll('span.scalevalue')) {
                e.style.borderBottom = `4px solid ${scale(e.innerHTML)}`;
            }
            for(var e of document.querySelectorAll('span[data-scalevalue]')) {
                e.style.borderBottom = `4px solid ${scale(e.attributes['data-scalevalue'].value)}`;
            }
        }


        var div = L.DomUtil.create('div', 'info legend category');
        return div;
    };


    legend.getColor = function(data) {
        var d = MAP.value(data);

        if(d.length==1) {
            return {'fillColor': scale(d[0])};
        } else {
            if(d.length>2) {
                console.log(d.length, 'too many in one place', d, data)
            }
            d.sort();
            var k = d.join('-');
            if(!patterns[k]) {
                patterns[k] = new L.StripePattern({
                    color: scale(d[0]),
                    spaceColor: scale(d[1]),
                    spaceOpacity: 1,
                    opacity: 1,
                    angle: 45,
                    weight: 4,
                    spaceWeight: 4});
            }
            return {'fillPattern': patterns[k]};
        }
    };

    return legend;
};

legend.linear = function(MAP) {
    var legend = L.control({position: 'topleft'});
    var scale = d3scale.scaleLinear().range(MAP.colorschemes).clamp(true);
    if(MAP.categories) {
        scale = scale.domain(MAP.categories);
    }

    legend.onAdd = function (map) {
        if(MAP.categories) {
            for(var e of document.querySelectorAll('span.scalevalue')) {
                e.style.borderBottom = `4px solid ${scale(e.innerHTML)}`;
            }
        }

        var div = L.DomUtil.create('div', 'info legend category');
        div.innerHTML = (MAP.categories_display_values || MAP.categories).map(
            (x,i) => `<span style="background: ${scale(x)}"></span>&nbsp;${MAP.categories_display?MAP.categories_display[i]:x}%`).join('<br />');
        return div;
    };


    legend.getColor = function(data) {
        var d = MAP.value(data);

        window.thescale = scale;

        return {'fillColor': scale(d)};
    };

    return legend;

}

legend.linear_or_null = function(MAP) {
    var legend = L.control({position: 'topleft'});
    var scale = d3scale.scaleLinear().range(MAP.colorschemes).clamp(true);
    if(MAP.categories) {
        scale = scale.domain(MAP.categories);
    }

    legend.onAdd = function (map) {
        if(MAP.categories) {
            for(var e of document.querySelectorAll('span.scalevalue')) {
                e.style.borderBottom = `4px solid ${scale(e.innerHTML)}`;
            }
        }

        var div = L.DomUtil.create('div', 'info legend category');
        div.innerHTML = (MAP.categories_display_values || MAP.categories).map(
            (x,i) => `<span style="background: ${scale(x)}"></span>&nbsp;${MAP.categories_display?MAP.categories_display[i]:x}%`).join('<br />');
        return div;
    };


    legend.getColor = function(data) {
        var d = MAP.value(data);

        window.thescale = scale;

        return {'fillColor': d[0]?scale(d[1]):MAP.colorscheme_null};
    };

    return legend;

}


export {legend};
