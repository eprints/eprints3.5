const dropbox = document.getElementById("pdf_upload_dropbox");
const input = document.getElementById("pdf_upload");
const preview = document.getElementById("pdf_upload_preview");

// Hide the input box as these vary massively between browsers
input.style.opacity = 0;
input.style.height = '1px';
input.style.width = '1px';

dropbox.addEventListener("drop", pdfUploadDrop);
input.addEventListener("change", updatePreview);

// It should be possible to set dropEffect in `dragenter` according to the spec but no browsers appear to implement this
// properly so for performance we set a `dropEffect` variable and then apply it in `dragover`. I guess in theory that
// could break multiple simultaneous drags but that feels like an extreme edge case.
var dropEffect = "copy";
dropbox.addEventListener("dragover", (ev) => {
	ev.preventDefault();
	ev.dataTransfer.dropEffect = dropEffect;
});
dropbox.addEventListener("dragenter", (ev) => {
	ev.preventDefault();
	const dt = ev.dataTransfer;
	// Using `indexOf` doesn't work in Safari so we use `contains` there
	if (dt.types && (dt.types.indexOf ? dt.types.indexOf('Files') != -1 : dt.types.contains('Files'))) {
		dropEffect = "copy";
		// Safari doesn't include items in drag events but we still want to show copy for it
		if (dt.items.length > 0) {
			if (!containsPDF(dt.items)) {
				dropEffect = "none";
			}
		}
	} else {
		dropEffect = "none";
	}
});

var transfer = new DataTransfer();
var table = undefined;

function updatePreview() {
	for (const file of input.files) {
		addPDF(file);
	}

	input.files = transfer.files;
}

function addPDF(file) {
	if (isNewFile(file)) {
		transfer.items.add(file);

		if (table === undefined) {
			preview.removeChild(preview.firstChild);
			const outerTable = preview.appendChild(document.createElement("table"));
			table = outerTable.appendChild(document.createElement("tbody"));
		}

		const tableRow = document.createElement("tr");
		tableRow.id = `previewTableRow_${transfer.items.length - 1}`;
		const fileName = tableRow.appendChild(document.createElement("th"));
		fileName.textContent = file.name;
		const fileSize = tableRow.appendChild(document.createElement("th"));
		fileSize.textContent = prettyFileSize(file.size);

		const removeItem = tableRow.appendChild(document.createElement("th"));
		const removeButton = removeItem.appendChild(document.createElement("button"));
		removeButton.style = "padding: 0; border: none; background: none; cursor: pointer;";
		removeButton.type = "button";
		const removeIcon = removeButton.appendChild(document.createElement("img"));
		removeIcon.alt = "Delete document";
		removeIcon.src = "/style/images/action_remove.png";
		removeButton.addEventListener("click", removePDF);

		table.appendChild(tableRow);
	}
}

function removePDF(ev) {
	var targetId = Number(ev.currentTarget.parentNode.parentNode.id.split('_').pop());

	transfer.items.remove(targetId);
	input.files = transfer.files;
	table.removeChild(table.childNodes[targetId]);
	const children = table.childNodes;
	while (targetId < children.length) {
		children[targetId].id = `previewTableRow_${targetId}`;
		targetId++;
	}

	if (children.length === 0) {
		table = undefined;
		preview.removeChild(preview.firstChild);
		var para = preview.appendChild(document.createElement("p"));
		para.appendChild(document.createTextNode("No files currently selected for upload"));
	}
}

function pdfUploadDrop(ev) {
	ev.preventDefault();

	for (const item of ev.dataTransfer.items) {
		if (item.kind === "file") {
			const file = item.getAsFile();

			if (typeof item.webkitGetAsEntry === "function") {
				uploadFileSystemEntry(item.webkitGetAsEntry());
			} else if (file.type === "application/pdf") {
				addPDF(file);
			}
		}
	}

	input.files = transfer.files;
}

var awaitingCount = 0;
function uploadFileSystemEntry(entry) {
	if (entry !== null) {
		if (entry.isDirectory) {
			const reader = entry.createReader();
			function readEntries() {
				reader.readEntries((entries) => {
					if (entries.length !== 0) {
						entries.forEach((entry) => {
							uploadFileSystemEntry(entry);
						});
						readEntries(); // readEntries only returns a batch so we have to call it recursively (test with over 100 files in Chrome)
					}
				});
			}
			readEntries();
		} else {
			awaitingCount++;
			entry.file((file) => {
				if (file.type === "application/pdf") {
					addPDF(file);
				}

				// This callback is delayed so we want to make sure we update `input.files` when they all finish
				awaitingCount--;
				if (awaitingCount === 0) {
					input.files = transfer.files;
				}
			});
		}
	}
}

function isNewFile(file) {
	for (const oldFile of transfer.files) {
		if (oldFile.name === file.name && oldFile.size === file.size && oldFile.lastModified === file.lastModified) {
			return false;
		}
	}
	return true;
}

function prettyFileSize(number) {
	if (number < 1e3) {
		return `${number} bytes`;
	} else if (number < 1e6) {
		return `${(number / 1e3).toFixed(1)} KB`;
	} else {
		return `${(number / 1e6).toFixed(1)} MB`;
	}
}

// Check if the passed items contain a pdf (or a folder).
// This is used to set the cursor so it doesn't use webkitGetAsEntry as that never works in drag events.
function containsPDF(items) {
	for (const item of items) {
		if (item.kind === "file") {
			// While browsers still define webkitGetAsEntry it just returns `null` in drag events so is useless
			if (item.type === "application/pdf" || item.type === "") {
				return true;
			}
		}
	}
	return false;
}
