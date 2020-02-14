(function() {
  tinymce.PluginManager.requireLangPack('googleimagesearch');
  tinymce.create('tinymce.plugins.GoogleImageSearchPlugin', {
    init: function(ed, url) {
      // Image path = ed.settings.googleimagesearch_path
      ed.addCommand('mceGoogleImageSearch', function() {
        return ed.windowManager.open({
          file: url + '/dialog.html',
          width: 560 + parseInt(ed.getLang('googleimagesearch.width', 0)),
          height: 340 + parseInt(ed.getLang('googleimagesearch.height', 0)),
          inline: 1
        }, {
          plugin_url: url
        });
      });
      ed.addButton('googleimagesearch', {
        title: 'googleimagesearch.title',
        cmd: 'mceGoogleImageSearch',
        image: url + '/img/googlesearch.jpeg'
      });
      return ed.onNodeChange.add(function(ed, cm, n) {
        return cm.setActive('googleimagesearch', n.nodeName === 'IMG');
      });
    },
    createControl: function(n, cm) {
      return null;
    },
    getInfo: function() {
      return {
        longname: 'Google Image Search plugin',
        author: 'Edutor',
        version: '1.0'
      };
    }
  });
  return tinymce.PluginManager.add('googleimagesearch', tinymce.plugins.GoogleImageSearchPlugin);
})();
