class Lightbox {
	imageURLs = [];

	// Set up the lightbox on any link with the class `className`
	constructor(className) {
		let i = 0;
		for (const element of document.getElementsByClassName(className)) {
			this.imageURLs.push(element.getAttribute('href'));

			const index = i;
			element.addEventListener('click', (ev) => {
				this.show(index);
				ev.preventDefault();
			});

			i++;
		}
	}

	// Show the lightbox for the image with index `imageIndex`
	show(imageIndex) {
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

		// Close if the overlay, lightbox or close button is pressed.
		overlay.addEventListener('click', this.close);
		lightbox.addEventListener('click', this.close);
		document.getElementById('bottomNavClose').firstChild.addEventListener('click', this.close);

		const loadingSpinner = document.getElementById('loading');
		const lightboxImage = document.getElementById('lightboxImage');
		loadingSpinner.style.display = '';
		lightboxImage.style.display = 'none';

		// We create the new image separately and then swap it in once it has
		// finished 'decoding' so that there are no flickers while it loads and it
		// ensures it is the correct size.
		const newImage = new Image();
		newImage.src = this.imageURLs[imageIndex];
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
	}

	// Close the lightbox and fade the overlay out
	close(ev) {
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
	}
}

document.addEventListener('DOMContentLoaded', () => {
	new Lightbox('lightbox');
});

