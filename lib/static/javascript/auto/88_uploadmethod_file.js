max_size = 1024 * 1024 * 1024 // 1 GiB default for https://httpd.apache.org/docs/2.4/mod/core.html#limitrequestbody

class Screen_EPrint_UploadMethod_File {
	component = undefined;
	prefix = undefined;
	container = undefined;
	parameters = undefined;

	constructor(prefix, component, evt) {
		this.component = component;
		this.prefix = prefix;
		this.form = document.querySelector('#main_content form')
		var div = document.getElementById(prefix + '_dropbox');
		this.container = div;

		this.parameters = {
			screen:		this.form.querySelector('[id="screen"]').getAttribute("value"),
			eprintid:	this.form.querySelector('[id="eprintid"]').getAttribute("value"),
			stage:		this.form.querySelector('[id="stage"]').getAttribute("value"),
			component:	component,
		}
	}

	dragCommence (evt) {
		var event = evt.memo.event;
		if (event.dataTransfer.types[0] == 'Files' || event.dataTransfer.types[0] == 'application/x-moz-file') {
			this.container.classList.add('ep_dropbox');
			document.getElementById(this.prefix + '_dropbox_help').style.display = '';
			document.getElementById(this.prefix + '_file').style.display = 'none';
		}
	}

	dragFinish (evt) {
		this.container.classList.remove('ep_dropbox');
		document.getElementById(this.prefix + '_dropbox_help').style.display = 'none';
		document.getElementById(this.prefix + '_file').style.display = '';
	}

	/*
	 * Handle a drop event on the HTML element
	 */
	drop (evt) {
		var files = evt.dataTransfer.files;
		var count = files.length;

		if (count == 0){
			return;
		}

		this.handleFiles(files);
	}

	/*
	 * Handle a list of files dropped
	 */
	handleFiles (files) {
		// User dropped a lot of files, did they really mean to?
		if (files.length > 5) {
			eprints.currentRepository().phrase(
				{
					'Plugin/Screen/EPrint/UploadMethod/File:confirm_bulk_upload': {
						'n': files.length
					}
				},
				(function (phrases) {
					if (confirm(phrases['Plugin/Screen/EPrint/UploadMethod/File:confirm_bulk_upload']))
						for (var i = 0; i < files.length; ++i)
							if (this.checkFilesize(files[i])) {
								this.processFile(files[i]);
							}
				}).bind(this)
			);
		}
		else
		{
			for (var i = 0; i < files.length; ++i) {
				if (this.checkFilesize(files[i])) {
					this.processFile(files[i]);
				}
			}
		}
	}

	/*
	 * Check file size before uploading.
	 */
	checkFilesize (file) {

		if (file.size < max_size) {
			return true;
		}

		const max_size_mib = max_size / 1024 / 1024;

		eprints.currentRepository().phrase(
			{ 'Plugin/Screen/EPrint/UploadMethod/File:filesize_too_big': {} },
			function (phrase) {
				alert(file.name + ": \n" + phrase["Plugin/Screen/EPrint/UploadMethod/File:filesize_too_big"] + " " + max_size_mib + " MiB.");
			}
		);

		return false;
	}

	/*
	 * Process a single file.
	 */
	processFile (file) {

		const fileFormId = `${this.prefix}_file`;

		const input = document.getElementById(fileFormId);
		const form = input.closest('form');
		const formData = new FormData(form);


		formData.set(fileFormId, file);

		UploadMethod_process_file(form, formData, this.prefix, this.component, file.name);
	}
};

const UploadMethod_process_file = (form, formData, prefix, component, fileLabel) => {
	const uuid = generateUUID();
	const progress = `${uuid}_progress`;

	const _xhr = new XMLHttpRequest();

	// progress status
	const progressRow = document.createElement('div');
	progressRow.setAttribute('id', progress);

	const progressContainer = progressRow;

	// file name
	const fileNameDiv = document.createElement('div');
	fileNameDiv.append(fileLabel);

	progressRow.append(fileNameDiv);

	// file size
	progressContainer.progress_size = document.createElement('div');
	progressRow.append(progressContainer.progress_size);

	// progress bar
	const progressBarDiv = document.createElement('div');

	progressRow.append(progressBarDiv);
	progressContainer.progress_bar = new EPrintsProgressBar({}, progressBarDiv);

	// progress text
	progressContainer.progress_info = document.createElement('div');
	progressRow.append(progressContainer.progress_info);

	// cancel button
	const cancelButton = document.createElement('button');

	cancelButton.textContent = 'Cancel';
	cancelButton.setAttribute('class', 'ep_form_action_button');

	cancelButton.addEventListener('click', function () {
		_xhr.abort();
		progressRow.remove();
	});

	const cancelDiv = document.createElement('div');
	cancelDiv.append(cancelButton);
	progressRow.append(cancelDiv);

	eprints.currentRepository().phrase({ 'lib/submissionform:action_cancel': {} }, function (phrases) {
		cancelButton.textContent = phrases['lib/submissionform:action_cancel'];
	});

	document.getElementById(`${prefix}_progress_table`).append(progressRow);

	// Build the upload URL.

	const uploadUrl = new URL(form.getAttribute('action'), window.location.href);

	uploadUrl.searchParams.set('progressid', uuid);
	uploadUrl.searchParams.set('ajax', 'add_format');

	// Mark this request as an internal button to the server code. Internal
	// buttons will keep the user on the same stage in the workflow.

	formData.set(`_internal_${prefix}_add_format`, 'Upload');

	// Only process this particular component.

	formData.set('component', component);

	// Do the upload using XMLHttpRequest instead of Fetch so that we can get
	// upload progress at the same time. A FormData object is used so that
	// the upload content does not need to fit inside browser memory.

	_xhr.addEventListener('load', function () {

		const matches = _xhr.responseText.match(/UploadMethod_file_stop\( '([0-9A-F]*)', ([0-9]*) \)/);

		if (matches) {

			const uuid = matches[1];
			const docid = matches[2];

			progressRow.remove();

			if (docid) {
				Component_Documents.instances.forEach((instance) => instance.refresh_document(docid));
			}
		}
	});

	_xhr.upload.addEventListener('progress', function (event) {

		const percent = Math.floor(event.loaded / event.total * 100);

		progressContainer.progress_bar.update(percent / 100, percent + '%');
		progressContainer.progress_info.textContent = percent + '%';
		progressContainer.progress_size.textContent = humanFilesize(event.loaded) + " / " + humanFilesize(event.total);
	});

	_xhr.open('POST', uploadUrl);
	_xhr.send(formData);
}

const UploadMethod_file_change = (input, component, prefix) => {
	if (input.value) {

		const form = input.closest('form');
		const formData = new FormData(form);
		const fileLabel = input.value.replace(/.*[^\\/][\\/]/, '');

		var filesizes_ok = true;
		for (var i = 0; i < input.files.length; i++)
		{
			filesizes_ok = UploadMethod_check_filesize( input.files[i] );
			if ( ! filesizes_ok ) { break }
		}

		if ( filesizes_ok ) {
			UploadMethod_process_file(form, formData, prefix, component, fileLabel);
		}
	}
}

function UploadMethod_check_filesize( file ) {

	if (file.size < max_size) {
                return true;
        }

        const max_size_mib = max_size / 1024 / 1024;

        eprints.currentRepository().phrase(
                { 'Plugin/Screen/EPrint/UploadMethod/File:filesize_too_big': {} },
                function (phrase) {
                        alert(file.name + ": \n" + phrase["Plugin/Screen/EPrint/UploadMethod/File:filesize_too_big"] + " " + max_size_mib + " MiB.");
                }
       );
}
