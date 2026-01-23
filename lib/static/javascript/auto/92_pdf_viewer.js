window.onload = () => {
	let pdfWrapperElem = document.querySelector("#pdf-viewer-wrapper")

	if( pdfWrapperElem != null )
	{
		let pdfElem = pdfWrapperElem.querySelector("embed")
		let pdfOverlayElem = document.querySelector("#pdf-viewer-overlay")
		let pdfButtonElem = document.querySelector("#pdf-viewer-button")
		let pdfButtonElemToggle = document.querySelector("#pdf-viewer-button-toggle")

		let pdfWrapperRectInfo = pdfWrapperElem.getBoundingClientRect()	
		pdfOverlayElem.style.height = pdfWrapperRectInfo['height'] + "px"
		pdfOverlayElem.style.width = pdfWrapperRectInfo['width'] + "px"

		pdfButtonElem.classList.remove('d-none');

		// button action
		pdfButtonElem.addEventListener('click', () => {
			pdfOverlayElem.style.display = 'none'
			pdfElem.style.height = ( window.innerHeight * 0.75 ) + "px"
			window.scrollTo( 0, ( pdfWrapperRectInfo['top'] - window.innerHeight * 0.1 ) );
			pdfButtonElemToggle.classList.remove("d-none")
		})
		pdfButtonElemToggle.addEventListener("click", () => {
			let pdfButtonToggleClose = pdfButtonElemToggle.querySelector(".bi-arrows-collapse");
			let pdfButtonToggleOpen = pdfButtonElemToggle.querySelector(".bi-arrows-expand");
			if( pdfButtonToggleClose.classList.contains('d-none') ) {
				// open
				pdfButtonToggleClose.classList.remove('d-none')
				pdfButtonToggleOpen.classList.add('d-none')
				pdfElem.style.height = ( window.innerHeight * 0.75 ) + "px"
				window.scrollTo( 0, ( pdfWrapperRectInfo['top']  ) );
			} else {
				//close
				pdfButtonToggleClose.classList.add('d-none')
				pdfButtonToggleOpen.classList.remove('d-none')
				pdfElem.style.height = ( window.innerHeight * 0.40 ) + "px"
			}
		})
	}
}
