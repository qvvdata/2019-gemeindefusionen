function getEmbed() {
  var frame_id = 'qvvdata__'+(document.location.pathname+document.location.hash+document.location.search).replace(/[^a-zA-Z0-9]/g,'_');
  var script_tag = document.getElementById('script_pymembed');
  return ['<','script src="',script_tag.getAttribute('src'),'"><','/script>\n',
          '<div id="',frame_id,'"></div>\n',
          '<','script>\n',
          "var pymParent_",frame_id," = new pym.Parent('",frame_id,"', '",
            document.location,
          "', {});",
          '\n<','/script>'].join('');
}

export { getEmbed };
