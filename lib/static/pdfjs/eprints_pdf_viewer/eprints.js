// Defines a custom EPrints-API to access metadata from the PDF Viewer example via messages
// This can be more easily communicated by javascript/auto/pdf_api.js
// Also a place to put any EPrints customisations to UI, etc if needed
window.addEventListener('load', function() {
	// Listen to any messages (API is done via message system)
	window.addEventListener('message', function(e) {
		let action = e.data[0];
		if(action === 'go_to_page') {
			let page = e.data[1];
			PDFViewerApplication.eventBus.dispatch("pagenumberchanged", {
				source: self,
				value: page
			});
		} else if(action === 'get_current_page') {
			window.parent.postMessage(['current_page', PDFViewerApplication.page], '*');
		} else if(action === 'get_document_metadata') {
			window.parent.postMessage(['document_metadata', PDFViewerApplication.documentInfo], '*');
		} else if(action === 'highlight_term') {
			let term = e.data[1];
			document.getElementById("viewFindButton").click();
			document.getElementById("findHighlightAll").click();
			document.getElementById("findInput").value = term;
			var evt = document.createEvent("HTMLEvents");
			evt.initEvent("input", false, true);
			document.getElementById("findInput").dispatchEvent(evt);
		}
	}, false);
});
