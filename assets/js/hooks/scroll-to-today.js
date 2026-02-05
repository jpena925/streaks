export default {
	mounted() {
		this.scrollToToday();
	},

	updated() {
		if (!this.userScrolled) {
			this.scrollToToday();
		}
	},

	scrollToToday() {
		const totalWeeks = parseInt(this.el.dataset.totalWeeks, 10);
		const currentWeekIndex = parseInt(this.el.dataset.currentWeekIndex, 10);

		if (isNaN(totalWeeks) || isNaN(currentWeekIndex)) return;

		const innerContent = this.el.querySelector(".inline-block");
		if (!innerContent) return;

		const contentWidth = innerContent.scrollWidth;
		const columnWidth = contentWidth / totalWeeks;

		const weeksOfContext = 5;
		const targetColumn = Math.max(0, currentWeekIndex - weeksOfContext);
		const targetScroll = targetColumn * columnWidth;

		this.el.scrollLeft = targetScroll;

		this.el.addEventListener(
			"scroll",
			() => {
				this.userScrolled = true;
				// Reset after 2 seconds of no scrolling
				clearTimeout(this.scrollTimeout);
				this.scrollTimeout = setTimeout(() => {
					this.userScrolled = false;
				}, 2000);
			},
			{ passive: true }
		);
	},
};
