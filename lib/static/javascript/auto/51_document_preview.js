document.addEventListener("DOMContentLoaded", function () {
	const previews = document.getElementsByClassName('ep_document_preview_pdf');
	Array.prototype.forEach.call(previews, (elem) => pdf_api_load_pdf(elem.getAttribute('div-id'), elem.getAttribute('pdf-url')));
});
