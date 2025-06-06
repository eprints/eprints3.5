var initTinyMCE = function(id){
        tinymce.init({
                selector: id,
		height: 500,
		width: 700,
		menubar: false,
		toolbar: 'undo redo | insert | styleselect | bold italic | alignleft aligncenter alignright alignjustify | bullist numlist outdent indent | link image',
		plugins: [
			'advlist autolink lists link image charmap print preview anchor',
			'searchreplace visualblocks code fullscreen',
			'insertdatetime media table contextmenu paste code'
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


var initTinyMCEReadOnly = function(id){
        tinymce.init({
                selector: id,
		height: 500,
		width: 700,
		menubar: false,
		toolbar: 'undo redo | insert | styleselect | bold italic | alignleft aligncenter alignright alignjustify | bullist numlist outdent indent | link image',
		plugins: [
			'advlist autolink lists link image charmap print preview anchor',
			'searchreplace visualblocks code fullscreen',
			'insertdatetime media table contextmenu paste code'
		],
		readonly: 1,
        });
};
