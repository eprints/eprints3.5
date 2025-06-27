// Show the lightbox for the given `imageLink`.
const showLightboxPreview = (imageLink) => {
	const overlay = document.getElementById('overlay');
	overlay.style.width = Math.max(document.body.scrollWidth, self.innerWidth) + 'px';
	overlay.style.height = Math.max(document.body.scrollHeight, self.innerHeight) + 'px';

	// Fade from 0.0 to 0.8 over the course of 200ms
	overlay.style.opacity = 0;
	let fadeIndex = 0;
	const intervalId = setInterval(() => {
		fadeIndex++;
		overlay.style.opacity = 0.04 * fadeIndex;
		overlay.style.display = '';
		if (fadeIndex === 20) {
			clearInterval(intervalId);
		}
	}, 10);

	// Hide the 'Prev' and 'Next' links as we don't yet handle them
	document.getElementById('prevLink').style.display = 'none';
	document.getElementById('nextLink').style.display = 'none';

	const lightbox = document.getElementById('lightbox');
	lightbox.style.top = document.documentElement.scrollTop + (window.innerHeight / 10) + 'px';
	lightbox.style.display = '';

	// Close the lightbox if the overlay, lightbox or close button is pressed.
	// This checks that it is the exact element being pressed so that only
	// pressing to the side of the lightbox not actually on it will close it.
	overlay.addEventListener('click', closeLightboxPreview);
	lightbox.addEventListener('click', closeLightboxPreview);
	document.getElementById('bottomNavClose').firstChild.addEventListener('click', closeLightboxPreview);

	const loadingSpinner = document.getElementById('loading');
	const lightboxImage = document.getElementById('lightboxImage');
	loadingSpinner.style.display = '';
	lightboxImage.style.display = 'none';

	// We create the new image separately and then swap it in once it has
	// finished 'decoding' so that there are no flickers while it loads and it
	// ensures it is the correct size.
	const newImage = new Image();
	newImage.src = imageLink;
	newImage.decode().then(() => {
		const newWidth = newImage.width + 20 + 'px';

		const outerImageContainer = document.getElementById('outerImageContainer');
		outerImageContainer.style.width = newWidth;
		outerImageContainer.style.height = newImage.height + 'px';

		document.getElementById('imageDataContainer').style.width = newWidth;

		// Duplicate the relevant attributes and then swap the elements.
		newImage.id = lightboxImage.id;
		newImage.alt = lightboxImage.alt;
		lightboxImage.replaceWith(newImage);

		lightboxImage.style.display = '';
		loadingSpinner.style.display = 'none';
	});
};

// Close the lightbox and fade the overlay out
function closeLightboxPreview(ev) {
	// If this isn't the element we added the listener on (aka it has bubbled)
	// then we don't want to close because otherwise it will close while
	// clicking anywhere on the lightbox.
	if (ev.srcElement === this) {
		// Fade the overlay from 0.8 to 0.0 in 200ms
		const overlay = document.getElementById('overlay');
		let fadeIndex = 0;
		const intervalId = setInterval(() => {
			fadeIndex++;
			overlay.style.opacity = 0.8 - 0.04 * fadeIndex;
			if (fadeIndex === 20) {
				overlay.style.display = 'none';
				clearInterval(intervalId);
			}
		}, 10);

		document.getElementById('lightbox').style.display = 'none';

		// This is a '#' link so if we don't prevent default it jumps to the
		// top of the page when closing.
		ev.preventDefault();
	}
};

