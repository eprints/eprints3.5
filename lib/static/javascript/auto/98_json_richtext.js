var initJsonTinyMCE = function(id) {
	tinymce.init({
		selector: id,
		height: 500,
		width: 700,
		menubar: false,
		license_key: 'gpl', // TinyMCE is licensed under GPLv2+ so valid in LGPLv3
		toolbar: 'undo redo | insert | styleselect | bold italic | alignleft aligncenter alignright alignjustify | bullist numlist outdent indent | link image',
		plugins: [
			'advlist', 'autolink', 'lists', 'link', 'image', 'charmap',
			'preview', 'anchor', 'searchreplace', 'visualblocks', 'code',
			'fullscreen', 'insertdatetime', 'media', 'table',
		],
		setup: function(ed) {
			ed.on('change', function(e) {
				tinymce.triggerSave();

				var origElem = ed.getElement();
				origElem.dispatchEvent(new Event('change'));
			});

			ed.on('focusout', function(e) {
				var origElem = ed.getElement();
				origElem.dispatchEvent(new Event('focusout'));
			});
		},
	});
};


var initJsonTinyMCEReadOnly = function(id) {
	tinymce.init({
		selector: id,
		height: 500,
		width: 700,
		menubar: false,
		license_key: 'gpl', // TinyMCE is licensed under GPLv2+ so valid in LGPLv3
		toolbar: 'undo redo | insert | styleselect | bold italic | alignleft aligncenter alignright alignjustify | bullist numlist outdent indent | link image',
		plugins: [
			'advlist', 'autolink', 'lists', 'link', 'image', 'charmap',
			'preview', 'anchor', 'searchreplace', 'visualblocks', 'code',
			'fullscreen', 'insertdatetime', 'media', 'table',
		],
		readonly: 1,
	});
};
