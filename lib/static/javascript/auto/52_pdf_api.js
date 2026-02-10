// Methods to more easily communicate with the EPrints pdfjs API defined in pdfjs/eprints_pdf_viewer/eprints.js
// Provide a window, and this will do the messaging and waiting for messages
// For methods where responses are expected, you get back a promise, not a variable

// Load a PDF into a iframe by giving the ID of the outer div, and the pdf url
// Optionally, also provide a post-load callback function
function pdf_api_load_pdf(id, url, load_function) {
	// Set-up the parent div properly
	document.getElementById(id).style.width = '100%';
	// offsetParent is needed so that go_to_page will work
	document.getElementById(id).setAttribute('offsetParent', '10px');

	// No src yet, because of the on-load function
	let iframe = document.createElement('iframe');
	iframe.setAttribute("width", "100%");
	iframe.setAttribute("height", "100%");
	iframe.setAttribute("loading", "lazy");
	iframe.setAttribute("id", id + "_iframe");
	document.getElementById(id).append(iframe);

	if(load_function) {
		document.getElementById(id + "_iframe").on('load', load_function);
	}

	// I don't think it will ever load faster than the onload function being set, but just in-case
	document.getElementById(id + "_iframe").setAttribute('src', '/pdfjs/eprints_pdf_viewer/viewer.html?file=' + url)
}

// Can get the window for the iframe by giving the ID of the outer div
function pdf_api_get_window_for_id(id) {
	return document.getElementById(id + "_iframe").contentWindow;
}

// Move the PDF to a particular page
function pdf_api_go_to_page(pdf_window, page) {
	pdf_window.postMessage(['go_to_page', Number(page)], '*');
}

// Get the current page from the PDF
// Returns a promise with the result
async function pdf_api_get_current_page(pdf_window) {
	let current_page = 0;

	// Sets up the listener for a response
	function pageListener(event) {
		let action = event.data[0];
		if(action === 'current_page') {
			current_page = event.data[1];
			window.removeEventListener('message', pageListener);
		}
	}
	window.addEventListener('message', pageListener, false);

	// Send the message, this will trigger a response with the answer
	pdf_window.postMessage(['get_current_page'], '*');

	// Promise will loop until it gets a result (with a short delay just in-case it is slow)
	const promise = new Promise((resolve, reject) => {
		const loop = () => current_page !== 0 ? resolve(current_page) : setTimeout(loop, 100)
		loop();
	});

	return promise;
}

// Get the metadata from the PDF
// Returns a promise with the result
async function pdf_api_get_metadata(pdf_window) {
	let metadata = null;

	// Sets up the listener for a response
	function pageListener(event) {
		let action = event.data[0];
		if(action === 'document_metadata') {
			metadata = event.data[1];
			window.removeEventListener('message', pageListener);
		}
	}
	window.addEventListener('message', pageListener, false);

	// Send the message, this will trigger a response with the answer
	pdf_window.postMessage(['get_document_metadata'], '*');

	// Promise will loop until it gets a result (with a short delay just in-case it is slow)
	const promise = new Promise((resolve, reject) => {
		const loop = () => metadata !== null ? resolve(metadata) : setTimeout(loop, 100)
		loop();
	});

	return promise;
}

// Highlights a term in the document
function pdf_api_highlight_term(pdf_window, term) {
	pdf_window.postMessage(['highlight_term', term], '*');
}
