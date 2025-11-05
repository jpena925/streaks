# Streaks - TODO

## Things to Do

### 1. Design Cleanup

- [x] Remove gradients (backgrounds, text, badges, buttons)
- [x] Remove hover scale/transform effects
- [x] Pick one shadow depth (or just use borders) - using borders mostly
- [x] Pick one border-radius value - using `rounded` (4px)
- [x] Try terminal color scheme (green/amber on dark, or brutalist black/white)

### 2. Split Up the LiveView

Current `index.ex` is 399 lines. Break it into:

- [x] Extract `habit_component` → `components/habit_card.ex`
- [x] Extract `habit_cube` → `components/habit_cube.ex`
- [x] Extract quantity modal → `components/quantity_modal.ex`
- [x] Main `index.ex` should just be orchestration

### 3. Edit Quantities

- [x] Click completed box → show modal
- [x] Modal shows: current value, edit input, Remove button
- [x] Can update or delete the completion

### 4. Habit Reordering

- [x] Add drag handle icon (⋮⋮) to habit card
- [x] Add `position` field to habits table
- [x] Implement drag-and-drop
- [x] Save new order

### 5. Use Streams (maybe)

Instead of reassigning full habits list every time:

- [ ] Convert to `stream(:habits, habits)`
- [ ] Use `stream_insert` and `stream_delete` for updates
- [ ] Should be faster with many habits

### 6. Other Stuff (later)

- Archive habits (field exists, no UI yet)
- Add database indexes
- Fix timezone edge cases
- Better mobile grid experience
- Quantity input validation


