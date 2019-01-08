var maps = {};

maps['parteienfoerderungen_gemeinden_2017'] = {
  title: 'Wie hoch die Parteienförderung Ihrer Gemeinde war',
  description: `Verbuchte Ausgaben pro Kopf für Transfers an private Organisationen ohne Erwerbszweck für gewählte Gemeindeorgane im Jahr 2017.<br />
  Farben: <span class="scalevalue">unterdurchschnittlich</span>, <span class="scalevalue">durchschnittlich</span>, <span class="scalevalue">überdurchschnittlich</span>`,
  data: 'parteienfoerderungen_gemeinden_2017.csv',
  source: 'Statistik Austria',
  datakey: 'Gemeindename',
  scale: 'category-multi',
  search: true,
  colorschemes: [['#f1f1f1', '#62a87c', '#9B9B9B','#af3b6e']],
  categories: ['keine', 'unterdurchschnittlich', 'durchschnittlich', 'überdurchschnittlich'],
  value: (d) => (isNaN(d.sollprokopf) || d.sollprokopf == 0) ? ['keine'] : [(d.sollprokopf<1.3 ? 'unterdurchschnittlich' : (d.sollprokopf < 2.81 ? 'durchschnittlich' : 'überdurchschnittlich' ))],
  tooltip: function(d,p,pctfmt,numfmt) {
    if(d.sollprokopf==0) {
         return `In ${d.name} wurde keine Parteienförderung im Haushalt verbucht.`
    }
    console.log(d.soll);
    return `In ${d.name} gingen ${numfmt(d.soll)} Euro aus der Gemeindekasse an Parteien. <br />
            Das sind ${pctfmt(d.sollprokopf)} Euro pro Gemeindebürger.
            Das ist im bundesweiten Vergleich ${(d.sollprokopf<1.3 ? 'unterdurchschnittlich' : (d.sollprokopf < 2.81 ? 'durchschnittlich' : 'überdurchschnittlich' ))} viel.`;
  },
  bundesland_message: `<a href="https://addendum.org" target="_blank"><img src="addendum-logo.png" /></a>`
};

Object.keys(maps).map((x) => {maps[x].map=x});

export { maps };
