// Touch hook for haptic feedback and long-press interactions
export default {
	mounted() {
		let longPressTimer = null;
		let touchStartX = 0;
		let touchStartY = 0;
		const LONG_PRESS_DURATION = 500; 
		const MOVE_THRESHOLD = 10; // pixels 

		this.el.addEventListener("touchstart", (e) => {
			const touch = e.touches[0];
			touchStartX = touch.clientX;
			touchStartY = touch.clientY;

			longPressTimer = setTimeout(() => {
				if (navigator.vibrate) {
					navigator.vibrate(50);
				}

				const longPressEvent = this.el.dataset.longPressEvent;
				if (longPressEvent) {
					this.pushEvent(longPressEvent, {
						habit_id: this.el.dataset.habitId,
						date: this.el.dataset.date,
					});
				}
			}, LONG_PRESS_DURATION);
		});

		this.el.addEventListener("touchmove", (e) => {
			if (longPressTimer) {
				const touch = e.touches[0];
				const deltaX = Math.abs(touch.clientX - touchStartX);
				const deltaY = Math.abs(touch.clientY - touchStartY);

				if (deltaX > MOVE_THRESHOLD || deltaY > MOVE_THRESHOLD) {
					clearTimeout(longPressTimer);
					longPressTimer = null;
				}
			}
		});

		this.el.addEventListener("touchend", () => {
			if (longPressTimer) {
				clearTimeout(longPressTimer);
				longPressTimer = null;

				if (navigator.vibrate) {
					navigator.vibrate(10);
				}
			}
		});

		this.el.addEventListener("touchcancel", () => {
			if (longPressTimer) {
				clearTimeout(longPressTimer);
				longPressTimer = null;
			}
		});
	},
};
