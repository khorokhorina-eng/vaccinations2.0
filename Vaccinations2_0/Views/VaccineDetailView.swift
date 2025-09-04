//
//  VaccineDetailView.swift
//  VaccineCalendar
//

import SwiftUI

struct VaccineDetailView: View {
    @EnvironmentObject var viewModel: VaccineViewModel
    @Environment(\.presentationMode) var presentationMode
    
    let vaccine: Vaccine
    @State private var record: VaccineRecord
    @State private var isEditing = false
    @State private var showingDatePicker = false
    @State private var tempDate = Date()
    @State private var tempVaccineName = ""
    @State private var tempBatchNumber = ""
    @State private var tempNotes = ""
    @State private var tempSideEffects = ""
    @State private var tempDoctorName = ""
    @State private var tempClinicName = ""
    
    init(vaccine: Vaccine) {
        self.vaccine = vaccine
        self._record = State(initialValue: VaccineRecord(vaccineId: vaccine.id))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Информация о прививке
                    vaccineInfoSection
                    
                    Divider()
                    
                    // Статус прививки
                    statusSection
                    
                    // Детали записи
                    if record.isDone {
                        Divider()
                        recordDetailsSection
                    }
                    
                    // Заметки
                    if ((record.notes?.isEmpty) == nil) {
                        Divider()
                        notesSection
                    }
                    
                    // Побочные эффекты
                    if ((record.sideEffects?.isEmpty) == nil) {
                        Divider()
                        sideEffectsSection
                    }
                }
                .padding()
            }
            .navigationTitle(vaccine.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Закрыть") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if record.isDone {
                        Button(isEditing ? "Готово" : "Изменить") {
                            if isEditing {
                                saveChanges()
                            }
                            isEditing.toggle()
                        }
                    }
                }
            }
            .onAppear {
                loadRecord()
            }
        }
    }
    
    // MARK: - Sections
    
    private var vaccineInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text(vaccine.disease)
                    .font(.headline)
            } icon: {
                Image(systemName: "shield.fill")
                    .foregroundColor(.blue)
            }
            
            Label {
                Text(vaccine.ageDescription)
                    .font(.headline)
            } icon: {
                Image(systemName: "calendar")
                    .foregroundColor(.orange)
            }
            
            if let profile = viewModel.childProfile {
                Label {
                    Text(dateFormatter.string(from: vaccine.scheduledDate(birthDate: profile.birthDate)))
                        .font(.headline)
                } icon: {
                    Image(systemName: "clock")
                    .foregroundColor(.purple)
                }
            }
            
            HStack {
                if vaccine.isMandatory {
                    Label("Обязательная", systemImage: "exclamationmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.green)
                        .cornerRadius(8)
                } else {
                    Label("Рекомендованная", systemImage: "info.circle.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
            
            if let description = vaccine.description {
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.top, 5)
            }
            
            if let notes = vaccine.notes {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
    }
    
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Статус")
                .font(.headline)
            
            HStack {
                Button(action: {
                    if record.isDone {
                        markAsNotDone()
                    } else {
                        showingDatePicker = true
                    }
                }) {
                    HStack {
                        Image(systemName: record.isDone ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                        Text(record.isDone ? "Сделано" : "Не сделано")
                            .font(.body)
                    }
                    .foregroundColor(record.isDone ? .green : .gray)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(record.isDone ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            if showingDatePicker && !record.isDone {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Дата вакцинации")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    DatePicker("", selection: $tempDate, in: ...Date(), displayedComponents: .date)
                        .datePickerStyle(GraphicalDatePickerStyle())
                    
                    TextField("Название вакцины (опционально)", text: $tempVaccineName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Заметки (опционально)", text: $tempNotes)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    HStack {
                        Button("Отмена") {
                            showingDatePicker = false
                            resetTempValues()
                        }
                        .foregroundColor(.red)
                        
                        Spacer()
                        
                        Button("Сохранить") {
                            markAsDone()
                        }
                        .foregroundColor(.blue)
                    }
                    .padding(.top)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
        }
    }
    
    private var recordDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Детали вакцинации")
                .font(.headline)
            
            if isEditing {
                editableDetailsView
            } else {
                readOnlyDetailsView
            }
        }
    }
    
    private var editableDetailsView: some View {
        VStack(spacing: 12) {
            DatePicker("Дата", selection: $tempDate, in: ...Date(), displayedComponents: .date)
            
            TextField("Название вакцины", text: $tempVaccineName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Серия вакцины", text: $tempBatchNumber)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Врач", text: $tempDoctorName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Клиника", text: $tempClinicName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Заметки", text: $tempNotes)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Побочные эффекты", text: $tempSideEffects)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
    
    private var readOnlyDetailsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let date = record.dateAdministered {
                DetailRow(label: "Дата", value: dateFormatter.string(from: date))
            }
            
            if let vaccineName = record.vaccineName, !vaccineName.isEmpty {
                DetailRow(label: "Вакцина", value: vaccineName)
            }
            
            if let batchNumber = record.batchNumber, !batchNumber.isEmpty {
                DetailRow(label: "Серия", value: batchNumber)
            }
            
            if let doctorName = record.doctorName, !doctorName.isEmpty {
                DetailRow(label: "Врач", value: doctorName)
            }
            
            if let clinicName = record.clinicName, !clinicName.isEmpty {
                DetailRow(label: "Клиника", value: clinicName)
            }
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Заметки")
                .font(.headline)
            
            Text(record.notes ?? "")
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
    
    private var sideEffectsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Побочные эффекты")
                .font(.headline)
            
            Text(record.sideEffects ?? "")
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Actions
    
    private func loadRecord() {
        if let existingRecord = viewModel.getRecord(for: vaccine) {
            record = existingRecord
            loadTempValues()
        }
    }
    
    private func loadTempValues() {
        tempDate = record.dateAdministered ?? Date()
        tempVaccineName = record.vaccineName ?? ""
        tempBatchNumber = record.batchNumber ?? ""
        tempNotes = record.notes ?? ""
        tempSideEffects = record.sideEffects ?? ""
        tempDoctorName = record.doctorName ?? ""
        tempClinicName = record.clinicName ?? ""
    }
    
    private func resetTempValues() {
        tempDate = Date()
        tempVaccineName = ""
        tempBatchNumber = ""
        tempNotes = ""
        tempSideEffects = ""
        tempDoctorName = ""
        tempClinicName = ""
    }
    
    private func markAsDone() {
        record.markAsDone(
            date: tempDate,
            vaccineName: tempVaccineName.isEmpty ? nil : tempVaccineName,
            notes: tempNotes.isEmpty ? nil : tempNotes
        )
        viewModel.updateVaccineRecord(record)
        showingDatePicker = false
        resetTempValues()
        loadTempValues()
    }
    
    private func markAsNotDone() {
        record.markAsNotDone()
        viewModel.updateVaccineRecord(record)
        resetTempValues()
    }
    
    private func saveChanges() {
        record.dateAdministered = tempDate
        record.vaccineName = tempVaccineName.isEmpty ? nil : tempVaccineName
        record.batchNumber = tempBatchNumber.isEmpty ? nil : tempBatchNumber
        record.notes = tempNotes.isEmpty ? nil : tempNotes
        record.sideEffects = tempSideEffects.isEmpty ? nil : tempSideEffects
        record.doctorName = tempDoctorName.isEmpty ? nil : tempDoctorName
        record.clinicName = tempClinicName.isEmpty ? nil : tempClinicName
        
        viewModel.updateVaccineRecord(record)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

struct VaccineDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let vaccine = Vaccine(
            id: "1",
            name: "БЦЖ",
            disease: "Туберкулез",
            ageInMonths: 0,
            ageDescription: "Новорожденные",
            isMandatory: true,
            description: "Вакцинация против туберкулеза",
            notes: nil
        )
        
        VaccineDetailView(vaccine: vaccine)
            .environmentObject(VaccineViewModel())
    }
}
