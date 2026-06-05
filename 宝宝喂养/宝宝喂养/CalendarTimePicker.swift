import SwiftUI

struct CalendarTimePicker: View {
    @Binding var selectedDate: Date
    var showsConfirmButton: Bool
    var onConfirm: () -> Void

    @State private var currentMonth: Date = Date()
    @State private var selectedHour: Int
    @State private var selectedMinute: Int

    private let calendar = Calendar.current
    private let weekdays = ["日", "一", "二", "三", "四", "五", "六"]

    init(selectedDate: Binding<Date>, showsConfirmButton: Bool = true, onConfirm: @escaping () -> Void) {
        self._selectedDate = selectedDate
        self.showsConfirmButton = showsConfirmButton
        self.onConfirm = onConfirm
        let hour = Calendar.current.component(.hour, from: selectedDate.wrappedValue)
        let minute = Calendar.current.component(.minute, from: selectedDate.wrappedValue)
        let month = Calendar.current.dateInterval(of: .month, for: selectedDate.wrappedValue)?.start ?? selectedDate.wrappedValue
        self._currentMonth = State(initialValue: month)
        self._selectedHour = State(initialValue: hour)
        self._selectedMinute = State(initialValue: minute)
    }

    private var isSelectedDateToday: Bool {
        calendar.isDateInToday(selectedDate)
    }

    private var isCurrentTimeValid: Bool {
        if !isSelectedDateToday { return true }
        let now = Date()
        let selected = selectedDate
        return selected <= now
    }

    private func isFutureDate(_ date: Date) -> Bool {
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfDate = calendar.startOfDay(for: date)
        return startOfDate > startOfToday
    }

    private func isNextMonthInFuture() -> Bool {
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) else { return true }
        let startOfNextMonth = calendar.startOfDay(for: nextMonth)
        let now = Date()
        let currentYear = calendar.component(.year, from: now)
        let currentMonthNum = calendar.component(.month, from: now)
        let nextYear = calendar.component(.year, from: startOfNextMonth)
        let nextMonthNum = calendar.component(.month, from: startOfNextMonth)
        if nextYear > currentYear { return true }
        if nextYear == currentYear && nextMonthNum > currentMonthNum { return true }
        return false
    }

    var body: some View {
        VStack(spacing: 0) {
            monthHeader
            weekdayHeader
            calendarGrid
            Divider()
            timeSection
            if showsConfirmButton {
                confirmButton
            }
        }
        .background(Color.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .onAppear {
            currentMonth = calendar.dateInterval(of: .month, for: selectedDate)?.start ?? selectedDate
            let hour = calendar.component(.hour, from: selectedDate)
            let minute = calendar.component(.minute, from: selectedDate)
            selectedHour = hour
            selectedMinute = minute
        }
    }

    var monthHeader: some View {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        let monthText = formatter.string(from: currentMonth)

        return HStack {
            Button(action: { changeMonth(by: -1) }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.primary)
                    .frame(width: 36, height: 36)
            }

            Spacer()

            Text(monthText)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color.onSurface)

            Spacer()

            Button(action: { changeMonth(by: 1) }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isNextMonthInFuture() ? Color.outlineVariant : Color.primary)
                    .frame(width: 36, height: 36)
            }
            .disabled(isNextMonthInFuture())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
    }

    var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(weekdays, id: \.self) { day in
                Text(day)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(day == "日" || day == "六" ? Color.primary : Color.outline)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }

    var calendarGrid: some View {
        let days = daysInMonth()

        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 4) {
            ForEach(days, id: \.self) { date in
                if let date = date {
                    dayCell(date: date)
                } else {
                    Color.clear.frame(height: 40)
                }
            }
        }
        .padding(.horizontal, 8)
    }

    func dayCell(date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)
        let isFuture = isFutureDate(date)
        let day = calendar.component(.day, from: date)

        return Button(action: {
            if !isFuture {
                selectDate(date)
            }
        }) {
            Text("\(day)")
                .font(.system(size: 16, weight: isSelected ? .bold : .regular))
                .foregroundColor(
                    isFuture ? Color.outlineVariant.opacity(0.4) :
                    (isSelected ? .white : (isToday ? Color.primary : Color.onSurface))
                )
                .frame(width: 36, height: 36)
                .background(
                    Group {
                        if isSelected && !isFuture {
                            Circle().fill(Color.primary)
                        } else if isToday {
                            Circle().stroke(Color.primary, lineWidth: 1.5)
                        }
                    }
                )
                .frame(maxWidth: .infinity)
                .frame(height: 40)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isFuture)
    }

    var timeSection: some View {
        VStack(spacing: 12) {
            Text("选择时间")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.outline)

            HStack(alignment: .center, spacing: 12) {
                Picker("小时", selection: $selectedHour) {
                    ForEach(0...23, id: \.self) { hour in
                        Text(String(format: "%02d", hour))
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .tag(hour)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 82, height: 132)
                .clipped()
                .compositingGroup()
                .onChange(of: selectedHour) { _, _ in
                    clampMinuteIfNeeded()
                    updateSelectedDate()
                }

                Text(":")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color.onSurface)
                    .frame(width: 16)

                Picker("分钟", selection: $selectedMinute) {
                    ForEach(0...59, id: \.self) { minute in
                        Text(String(format: "%02d", minute))
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .tag(minute)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 82, height: 132)
                .clipped()
                .compositingGroup()
                .onChange(of: selectedMinute) { _, _ in
                    updateSelectedDate()
                }
            }
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.surfaceContainerLow)
                    .frame(height: 46)
                    .allowsHitTesting(false)
            )
        }
        .padding(.vertical, showsConfirmButton ? 16 : 18)
    }

    private func clampMinuteIfNeeded() {
        guard isSelectedDateToday else { return }
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        if selectedHour > currentHour {
            selectedHour = currentHour
        }
        if selectedHour == currentHour && selectedMinute > currentMinute {
            selectedMinute = currentMinute
        }
    }

    var confirmButton: some View {
        Button(action: {
            updateSelectedDate()
            onConfirm()
        }) {
            Text("确认")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(isCurrentTimeValid ? Color.primary : Color.outlineVariant)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!isCurrentTimeValid)
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    func daysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let monthFirstWeekday = calendar.dateComponents([.weekday], from: monthInterval.start).weekday else {
            return []
        }

        let firstDayOffset = monthFirstWeekday - 1
        let daysInMonth = calendar.range(of: .day, in: .month, for: currentMonth)?.count ?? 30

        var days: [Date?] = Array(repeating: nil, count: firstDayOffset)

        for day in 1...daysInMonth {
            if let date = calendar.date(bySetting: .day, value: day, of: monthInterval.start) {
                days.append(date)
            }
        }

        let remaining = 42 - days.count
        if remaining > 0 {
            days.append(contentsOf: Array(repeating: nil, count: remaining))
        }

        return days
    }

    func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            if value > 0 && isNextMonthInFuture() { return }
            currentMonth = newMonth
        }
    }

    func selectDate(_ date: Date) {
        let hour = selectedHour
        let minute = selectedMinute
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute
        if calendar.date(from: components) != nil {
            if isFutureDate(date) { return }
            if calendar.isDateInToday(date) {
                let now = Date()
                let nowHour = calendar.component(.hour, from: now)
                let nowMinute = calendar.component(.minute, from: now)
                if hour > nowHour || (hour == nowHour && minute > nowMinute) {
                    components.hour = nowHour
                    components.minute = nowMinute
                    selectedHour = nowHour
                    selectedMinute = nowMinute
                }
            }
            if let finalDate = calendar.date(from: components) {
                selectedDate = finalDate
            }
        }
    }

    func updateSelectedDate() {
        var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        components.hour = selectedHour
        components.minute = selectedMinute
        if let newDate = calendar.date(from: components) {
            if newDate <= Date() {
                selectedDate = newDate
            }
        }
    }
}
