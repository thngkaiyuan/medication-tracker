import { getMedicationTiming, parseMedicationBackup } from './data.js';

class MedicationTracker {
            constructor() {
                this.dom = {
                    mainScreen: document.getElementById('mainScreen'),
                    recordsScreen: document.getElementById('recordsScreen'),
                    medicationsList: document.getElementById('medicationsList'),

                    medicationModal: document.getElementById('medicationModal'),
                    modalTitle: document.getElementById('modalTitle'),
                    medicationForm: document.getElementById('medicationForm'),
                    medicationFormBody: document.getElementById('medicationFormBody'),
                    deleteConfirmationText: document.getElementById('deleteConfirmationText'),
                    modalMedicationName: document.getElementById('modalMedicationName'),
                    modalTimeBetween: document.getElementById('modalTimeBetween'),
                    modalMaxDoses: document.getElementById('modalMaxDoses'),
                    modalCancelBtn: document.getElementById('modalCancelBtn'),
                    modalActionBtn: document.getElementById('modalActionBtn'),
                    deleteMedIconBtn: document.getElementById('deleteMedIconBtn'),

                    recordsHeader: document.getElementById('recordsHeader'),
                    editCurrentMedicationBtn: document.getElementById('editCurrentMedicationBtn'),
                    backToMainBtn: document.getElementById('backToMainBtn'),
                    recordsTitle: document.getElementById('recordsTitle'),
                    recordsContent: document.getElementById('recordsContent'),
                    addManualRecordBtn: document.getElementById('addManualRecordBtn'),
                    toast: document.getElementById('toast'),
                    addMedicationFooterBtn: document.getElementById('addMedicationFooterBtn'),
                    moreOptionsTriggerBtn: document.getElementById('moreOptionsTriggerBtn'),
                    optionsMenu: document.getElementById('optionsMenu'),
                    exportDataMenuBtn: document.getElementById('exportDataMenuBtn'),
                    importDataMenuBtn: document.getElementById('importDataMenuBtn'),
                    importFileInput: document.getElementById('importFile'),

                    actionChoiceModal: document.getElementById('actionChoiceModal'),
                    actionChoiceModalTitle: document.getElementById('actionChoiceModalTitle'),
                    actionChoiceLogBtn: document.getElementById('actionChoiceLogBtn'),
                    actionChoiceViewRecordsBtn: document.getElementById('actionChoiceViewRecordsBtn'),

                    recordEntryModal: document.getElementById('recordEntryModal'),
                    recordEntryModalTitle: document.getElementById('recordEntryModalTitle'),
                    recordEntryForm: document.getElementById('recordEntryForm'),
                    recordEntryFormBody: document.getElementById('recordEntryFormBody'),
                    recordEntryDate: document.getElementById('recordEntryDate'),
                    recordEntryTime: document.getElementById('recordEntryTime'),
                    recordEntryDeleteConfirmationText: document.getElementById('recordEntryDeleteConfirmationText'),
                    recordEntryCancelBtn: document.getElementById('recordEntryCancelBtn'),
                    recordEntryActionBtn: document.getElementById('recordEntryActionBtn'),
                    deleteRecordEntryBtn: document.getElementById('deleteRecordEntryBtn')
                };

                this.medications = this.loadMedications();
                this.currentRecordsMedication = null;
                this.editingMedicationId = null;
                this.confirmingDeleteMedication = false;
                this.actionChoiceMedicationId = null;

                this.editingRecordTimestamp = null;
                this.confirmingDeleteRecordEntry = false;
                this.activeMedicationForRecordEntry = null;


                this.isScreenTransitioning = false;
                this.toastTimeout = null;
                this.currentHistoryState = null;

                this.init();
            }

            init() {
                this.renderMedications();
                this.startTimeUpdater();
                this.setupEventListeners();
                window.addEventListener('popstate', (event) => this.handlePopState(event));
                if (!history.state || history.state.screen !== 'main') {
                    history.replaceState({ screen: 'main', medId: null }, "Main Screen", "#main");
                }
                this.currentHistoryState = 'main';
            }

            handlePopState(event) {
                const state = event.state;
                const targetScreen = state ? state.screen : null;
                console.log("PWA DEBUG: Popstate event. Target screen:", targetScreen, "Target Med ID:", state ? state.medId : "N/A");

                if (targetScreen === 'main' && this.recordsScreenActive()) {
                    this.hideRecords(true);
                } else if (targetScreen === 'records' && !this.recordsScreenActive() && state.medId) {
                    this.showRecords(state.medId, true);
                } else if (!targetScreen && this.recordsScreenActive()) {
                    this.hideRecords(true);
                }
                this.currentHistoryState = targetScreen || 'main';
            }

            recordsScreenActive() {
                return this.dom.recordsScreen.classList.contains('active');
            }


            startTimeUpdater() {
                setInterval(() => {
                    if (!this.isScreenTransitioning) {
                        this.renderMedications();
                    }
                }, 1000);
            }

            setupEventListeners() {
                this.dom.medicationForm.addEventListener('submit', (e) => {
                    e.preventDefault();
                    this.handleModalFormSubmit();
                });
                this.dom.medicationModal.addEventListener('click', (e) => {
                    if (e.target === this.dom.medicationModal) this.hideMedicationModal();
                });
                this.dom.modalCancelBtn.addEventListener('click', () => {
                    if (this.confirmingDeleteMedication) {
                        const medToEdit = this.medications.find(m => m.id === this.editingMedicationId);
                        if (medToEdit) this.prepareEditModal(medToEdit);
                        else this.hideMedicationModal();
                    } else {
                        this.hideMedicationModal();
                    }
                });

                this.dom.addMedicationFooterBtn.addEventListener('click', () => this.prepareAddModal());
                this.dom.moreOptionsTriggerBtn.addEventListener('click', (e) => {
                    e.stopPropagation();
                    this.toggleOptionsMenu();
                });
                this.dom.exportDataMenuBtn.addEventListener('click', async () => {
                    await this.exportData();
                    this.toggleOptionsMenu(false);
                });
                this.dom.importDataMenuBtn.addEventListener('click', () => {
                    this.dom.importFileInput.click();
                });

                this.dom.importFileInput.addEventListener('change', (event) => {
                    this.importData(event);
                    this.toggleOptionsMenu(false);
                });

                document.addEventListener('click', (event) => {
                    if (this.dom.optionsMenu.classList.contains('active') &&
                        !this.dom.optionsMenu.contains(event.target) &&
                        !this.dom.moreOptionsTriggerBtn.contains(event.target) &&
                        event.target !== this.dom.moreOptionsTriggerBtn
                        ) {
                        this.toggleOptionsMenu(false);
                    }
                });

                this.dom.editCurrentMedicationBtn.addEventListener('click', () => {
                    if (this.currentRecordsMedication) {
                        this.prepareEditModal(this.currentRecordsMedication);
                    }
                });
                this.dom.deleteMedIconBtn.addEventListener('click', () => {
                    this.prepareDeleteMedicationConfirmation();
                });

                this.dom.backToMainBtn.addEventListener('click', () => {
                    if (history.state?.screen === 'records') {
                        history.back();
                    } else { // Fallback if history state is unexpected
                        this.hideRecords(false);
                    }
                });


                this.dom.actionChoiceModal.addEventListener('click', (e) => {
                    if (e.target === this.dom.actionChoiceModal) this.hideActionChoiceModal();
                });
                this.dom.actionChoiceLogBtn.addEventListener('click', () => {
                    if (this.actionChoiceMedicationId) this.consumeMedication(this.actionChoiceMedicationId);
                    this.hideActionChoiceModal();
                });
                this.dom.actionChoiceViewRecordsBtn.addEventListener('click', () => {
                    if (this.actionChoiceMedicationId) this.showRecords(this.actionChoiceMedicationId);
                    this.hideActionChoiceModal();
                });

                this.dom.addManualRecordBtn.addEventListener('click', () => {
                    this.prepareRecordEntryModal();
                });
                this.dom.recordEntryModal.addEventListener('click', (e) => {
                    if (e.target === this.dom.recordEntryModal) this.hideRecordEntryModal();
                });
                this.dom.recordEntryForm.addEventListener('submit', (e) => {
                    e.preventDefault();
                    this.handleRecordEntryFormSubmit();
                });
                this.dom.recordEntryCancelBtn.addEventListener('click', () => {
                     if (this.confirmingDeleteRecordEntry) {
                        this.prepareRecordEntryModal(this.editingRecordTimestamp);
                    } else {
                        this.hideRecordEntryModal();
                    }
                });
                this.dom.deleteRecordEntryBtn.addEventListener('click', () => {
                    this.prepareDeleteRecordEntryConfirmation();
                });
            }

            toggleOptionsMenu(forceState) {
                if (typeof forceState === 'boolean') {
                    this.dom.optionsMenu.classList.toggle('active', forceState);
                } else {
                    this.dom.optionsMenu.classList.toggle('active');
                }
            }

            prepareAddModal() {
                this.editingMedicationId = null;
                this.confirmingDeleteMedication = false;
                this.dom.medicationForm.reset();
                this.dom.modalTitle.textContent = 'Add Medication';
                this.dom.modalActionBtn.textContent = 'Add';
                this.dom.modalActionBtn.className = 'modal-btn modal-confirm-btn';
                this.dom.deleteMedIconBtn.style.display = 'none';
                this.dom.medicationFormBody.style.display = 'block';
                this.dom.deleteConfirmationText.style.display = 'none';
                this.dom.modalCancelBtn.textContent = 'Cancel';

                this.dom.medicationModal.classList.add('active');
                setTimeout(() => this.dom.modalMedicationName.focus(), 50);
            }

            prepareEditModal(medication) {
                if (!medication) return;
                this.editingMedicationId = medication.id;
                this.confirmingDeleteMedication = false;
                this.dom.modalTitle.textContent = 'Edit Medication';
                this.dom.modalMedicationName.value = medication.name;
                this.dom.modalTimeBetween.value = medication.timeBetweenHours;
                this.dom.modalMaxDoses.value = medication.maxDosesPerDay || '';

                this.dom.modalActionBtn.textContent = 'Save Changes';
                this.dom.modalActionBtn.className = 'modal-btn modal-confirm-btn';
                this.dom.deleteMedIconBtn.style.display = 'block';
                this.dom.medicationFormBody.style.display = 'block';
                this.dom.deleteConfirmationText.style.display = 'none';
                this.dom.modalCancelBtn.textContent = 'Cancel';
                this.dom.medicationModal.classList.add('active');
            }

            prepareDeleteMedicationConfirmation() {
                if (!this.editingMedicationId) return;
                const medication = this.medications.find(m => m.id === this.editingMedicationId);
                if (!medication) return;

                this.confirmingDeleteMedication = true;
                this.dom.modalTitle.textContent = `Delete ${medication.name}?`;
                this.dom.medicationFormBody.style.display = 'none';
                this.dom.deleteConfirmationText.style.display = 'block';
                this.dom.deleteMedIconBtn.style.display = 'none';
                this.dom.modalActionBtn.textContent = 'Confirm Delete';
                this.dom.modalActionBtn.className = 'modal-btn modal-confirm-btn delete-confirm-style';
                this.dom.modalCancelBtn.textContent = 'Cancel';
            }


            hideMedicationModal() {
                this.dom.medicationModal.classList.remove('active');
                this.editingMedicationId = null;
                this.confirmingDeleteMedication = false;
                this.dom.modalTitle.textContent = 'Add Medication';
                this.dom.modalActionBtn.textContent = 'Add';
                this.dom.modalActionBtn.className = 'modal-btn modal-confirm-btn';
                this.dom.deleteMedIconBtn.style.display = 'none';
                this.dom.medicationFormBody.style.display = 'block';
                this.dom.deleteConfirmationText.style.display = 'none';
                this.dom.modalCancelBtn.textContent = 'Cancel';
                this.dom.medicationForm.reset();
            }

            handleModalFormSubmit() {
                if (this.confirmingDeleteMedication) {
                    this.deleteMedication();
                    return;
                }

                const name = this.dom.modalMedicationName.value.trim();
                const timeBetween = parseInt(this.dom.modalTimeBetween.value);
                const maxDoses = parseInt(this.dom.modalMaxDoses.value) || 0;

                if (!name || !timeBetween) {
                    this.showToast('Please fill in required fields.');
                    return;
                }

                if (this.editingMedicationId) {
                    const medIndex = this.medications.findIndex(m => m.id === this.editingMedicationId);
                    if (medIndex > -1) {
                        this.medications[medIndex] = {
                            ...this.medications[medIndex],
                            name,
                            timeBetweenHours: timeBetween,
                            maxDosesPerDay: maxDoses
                        };
                        this.saveAndRender();
                        this.showToast(`${name} updated.`);
                        if (this.currentRecordsMedication && this.currentRecordsMedication.id === this.editingMedicationId) {
                            this.currentRecordsMedication = this.medications[medIndex];
                            this.dom.recordsTitle.textContent = name;
                            this.updateRecordsDisplay();
                        }
                    }
                } else {
                    const newMedication = { id: Date.now().toString(), name, timeBetweenHours: timeBetween, maxDosesPerDay: maxDoses, records: [] };
                    this.medications.push(newMedication);
                    this.saveAndRender();
                    this.showToast(`${name} added successfully.`);
                }
                this.hideMedicationModal();
            }

            deleteMedication() {
                if (!this.editingMedicationId) return;
                const currentMedId = this.editingMedicationId; // Store before it's nulled
                const medicationName = this.medications.find(m => m.id === currentMedId)?.name || 'Medication';

                this.medications = this.medications.filter(m => m.id !== currentMedId);
                this.saveMedications();
                this.hideMedicationModal(); // This will nullify this.editingMedicationId

                if (this.currentRecordsMedication && this.currentRecordsMedication.id === currentMedId) {
                    if (history.state?.screen === 'records' && history.state?.medId === currentMedId) {
                         history.back();
                    } else {
                        this.hideRecords(false);
                    }
                }
                this.renderMedications();
                this.showToast(`${medicationName} deleted.`);
                // this.editingMedicationId is already nulled by hideMedicationModal
                this.confirmingDeleteMedication = false;
            }

            showActionChoiceModal(medication) {
                if (!medication) return;
                this.actionChoiceMedicationId = medication.id;
                this.dom.actionChoiceModalTitle.textContent = `Choose Action for ${medication.name}`;
                this.dom.actionChoiceModal.classList.add('active');
            }

            hideActionChoiceModal() {
                this.dom.actionChoiceModal.classList.remove('active');
                this.actionChoiceMedicationId = null;
            }

            prepareRecordEntryModal(timestampToEdit = null) {
                if (!this.currentRecordsMedication) {
                    this.showToast("Error: No medication selected to add/edit record for.");
                    return;
                }
                this.activeMedicationForRecordEntry = this.currentRecordsMedication;
                this.editingRecordTimestamp = timestampToEdit;
                this.confirmingDeleteRecordEntry = false;
                this.dom.recordEntryFormBody.style.display = 'block';
                this.dom.recordEntryDeleteConfirmationText.style.display = 'none';
                this.dom.recordEntryActionBtn.className = 'modal-btn modal-confirm-btn';
                this.dom.recordEntryCancelBtn.textContent = 'Cancel';


                if (timestampToEdit) {
                    this.dom.recordEntryModalTitle.textContent = 'Edit Record Entry';
                    this.dom.recordEntryActionBtn.textContent = 'Save Changes';
                    this.dom.deleteRecordEntryBtn.style.display = 'block';

                    const date = new Date(timestampToEdit);
                    const year = date.getFullYear();
                    const month = (date.getMonth() + 1).toString().padStart(2, '0');
                    const day = date.getDate().toString().padStart(2, '0');
                    this.dom.recordEntryDate.value = `${year}-${month}-${day}`;
                    const hours = date.getHours().toString().padStart(2, '0');
                    const minutes = date.getMinutes().toString().padStart(2, '0');
                    this.dom.recordEntryTime.value = `${hours}:${minutes}`;
                } else {
                    this.dom.recordEntryModalTitle.textContent = 'Add Manual Record';
                    this.dom.recordEntryActionBtn.textContent = 'Add Record';
                    this.dom.deleteRecordEntryBtn.style.display = 'none';
                    this.dom.recordEntryForm.reset();
                    const now = new Date();
                    const year = now.getFullYear();
                    const month = (now.getMonth() + 1).toString().padStart(2, '0');
                    const day = now.getDate().toString().padStart(2, '0');
                    this.dom.recordEntryDate.value = `${year}-${month}-${day}`;
                    const hours = now.getHours().toString().padStart(2, '0');
                    const minutes = now.getMinutes().toString().padStart(2, '0');
                    this.dom.recordEntryTime.value = `${hours}:${minutes}`;
                }
                this.dom.recordEntryModal.classList.add('active');
            }

            hideRecordEntryModal() {
                this.dom.recordEntryModal.classList.remove('active');
                this.editingRecordTimestamp = null;
                this.confirmingDeleteRecordEntry = false;
                this.activeMedicationForRecordEntry = null;
            }

            handleRecordEntryFormSubmit() {
                const targetMedication = this.activeMedicationForRecordEntry;

                if (this.confirmingDeleteRecordEntry) {
                    this.deleteRecordEntry();
                    return;
                }

                if (!targetMedication) {
                    this.showToast('Error: No medication context for record entry.');
                    this.hideRecordEntryModal();
                    return;
                }

                const dateStr = this.dom.recordEntryDate.value;
                const timeStr = this.dom.recordEntryTime.value;

                if (!dateStr || !timeStr) {
                    this.showToast('Please select both date and time.');
                    return;
                }

                const localDateTime = new Date(`${dateStr}T${timeStr}`);
                if (isNaN(localDateTime.getTime())) {
                    this.showToast('Invalid date or time format.');
                    return;
                }
                const newTimestamp = localDateTime.getTime();

                if (this.editingRecordTimestamp) {
                    const recordIndex = targetMedication.records.indexOf(this.editingRecordTimestamp);
                    if (recordIndex > -1) {
                        targetMedication.records.splice(recordIndex, 1, newTimestamp);
                        this.showToast('Record entry updated.');
                    } else {
                         this.showToast('Original record not found for update.');
                    }
                } else {
                    targetMedication.records.push(newTimestamp);
                    this.showToast('Manual record added.');
                }

                targetMedication.records.sort((a, b) => a - b);
                this.saveAndRender();
                this.updateRecordsDisplay();
                this.hideRecordEntryModal();
            }

            prepareDeleteRecordEntryConfirmation() {
                if (!this.editingRecordTimestamp || !this.activeMedicationForRecordEntry) return;
                this.confirmingDeleteRecordEntry = true;
                this.dom.recordEntryModalTitle.textContent = 'Delete This Entry?';
                this.dom.recordEntryFormBody.style.display = 'none';
                this.dom.recordEntryDeleteConfirmationText.style.display = 'block';
                this.dom.deleteRecordEntryBtn.style.display = 'none';
                this.dom.recordEntryActionBtn.textContent = 'Confirm Delete';
                this.dom.recordEntryActionBtn.className = 'modal-btn modal-confirm-btn delete-confirm-style';
                this.dom.recordEntryCancelBtn.textContent = 'Cancel';
            }

            deleteRecordEntry() {
                const targetMedication = this.activeMedicationForRecordEntry;
                if (!targetMedication || this.editingRecordTimestamp === null) return;

                const recordIndex = targetMedication.records.indexOf(this.editingRecordTimestamp);
                if (recordIndex > -1) {
                    targetMedication.records.splice(recordIndex, 1);
                    this.saveAndRender();
                    this.updateRecordsDisplay();
                    this.showToast('Record entry deleted.');
                } else {
                    this.showToast('Could not find record to delete.');
                }
                this.hideRecordEntryModal();
            }


            async exportData() {
                if (this.medications.length === 0) {
                    this.showToast('No data to export.');
                    return;
                }
                const jsonData = JSON.stringify(this.medications, null, 2);
                const fileName = `medication_tracker_backup_${new Date().toISOString().slice(0,10)}.json`;

                const blob = new Blob([jsonData], { type: 'application/json' });
                const url = URL.createObjectURL(blob);
                const a = document.createElement('a');
                a.href = url;
                a.download = fileName;
                document.body.appendChild(a);
                a.click();
                document.body.removeChild(a);
                URL.revokeObjectURL(url);
                this.showToast('Data exported successfully.');
            }

            importData(event) {
                const file = event.target.files[0];
                if (!file) {
                    return;
                }

                const reader = new FileReader();
                reader.onload = (e) => {
                    try {
                        this.medications = parseMedicationBackup(JSON.parse(e.target.result));
                        this.saveAndRender();
                        this.showToast(`Data imported successfully. ${this.medications.length} medication(s) loaded.`);
                    } catch (error) {
                        console.error('Error importing data:', error);
                        this.showToast(`Error importing data: ${error.message}`);
                    } finally {
                        event.target.value = null;
                    }
                };
                reader.onerror = () => {
                    this.showToast('Error reading file.');
                    event.target.value = null;
                };
                reader.readAsText(file);
            }


            consumeMedication(id) {
                const medication = this.medications.find(m => m.id === id);
                if (!medication) return;
                medication.records.push(Date.now());
                this.saveAndRender();
                this.showToast(`${medication.name} logged.`);
            }

            showRecords(id, isFromPopState = false) {
                if (this.isScreenTransitioning && !isFromPopState) return;
                const medication = this.medications.find(m => m.id === id);

                if (!medication) {
                    this.hideRecords();
                    return;
                }

                if (!isFromPopState && (!history.state || history.state.screen !== 'records' || history.state.medId !== id) ) {
                    history.pushState({ screen: 'records', medId: id }, `Records - ${medication.name}`, `#records/${id}`);
                }
                this.currentHistoryState = 'records';


                this.isScreenTransitioning = true;
                this.currentRecordsMedication = medication;

                this.dom.recordsTitle.textContent = medication.name;

                this.dom.mainScreen.style.transform = '';
                this.dom.recordsScreen.style.transform = '';

                this.dom.recordsScreen.classList.add('active');
                this.updateRecordsDisplay(); // Call AFTER .active class is added
                this.dom.mainScreen.classList.add('viewing-records');

                const onTransitionEnd = () => {
                    this.dom.recordsScreen.removeEventListener('transitionend', onTransitionEnd);
                    this.isScreenTransitioning = false;
                };
                this.dom.recordsScreen.addEventListener('transitionend', onTransitionEnd, { once: true });
            }

            hideRecords(isFromPopState = false) {
                if (this.isScreenTransitioning && this.currentRecordsMedication && !isFromPopState) return;
                if (!this.recordsScreenActive() && !isFromPopState) return;

                this.isScreenTransitioning = true;

                if (!isFromPopState && history.state?.screen === 'records') {
                     // This case is for UI elements like the back arrow triggering a history change
                     // history.back() is called by the event listener directly.
                     // This function will then be called again via popstate with isFromPopState = true.
                     // So, if !isFromPopState, we don't immediately animate out if a history action is pending.
                     // However, if called due to deletion, or if state is already 'main', we proceed.
                }

                if (isFromPopState || !history.state || history.state.screen !== 'records') {
                    this.dom.mainScreen.style.transform = '';
                    this.dom.recordsScreen.style.transform = '';
                    this.dom.recordsScreen.classList.remove('active');
                    this.dom.mainScreen.classList.remove('viewing-records');
                }
                this.currentHistoryState = 'main';


                const onTransitionEnd = () => {
                    this.dom.recordsScreen.removeEventListener('transitionend', onTransitionEnd);
                    this.currentRecordsMedication = null;
                    this.activeMedicationForRecordEntry = null;
                    this.isScreenTransitioning = false;
                    this.renderMedications();
                };

                const recordsScreenIsActuallyVisible = this.dom.recordsScreen.classList.contains('active') || getComputedStyle(this.dom.recordsScreen).transform !== 'none';

                if (recordsScreenIsActuallyVisible || isFromPopState) {
                     this.dom.recordsScreen.addEventListener('transitionend', onTransitionEnd, { once: true });
                } else {
                    this.currentRecordsMedication = null;
                    this.activeMedicationForRecordEntry = null;
                    this.isScreenTransitioning = false;
                    this.renderMedications();
                }
            }

            updateRecordsDisplay() {
                if (!this.currentRecordsMedication) {
                    this.dom.recordsContent.innerHTML = '<div class="empty-records">No medication selected.</div>';
                    return;
                }
                const records = this.currentRecordsMedication.records;
                if (!records || records.length === 0) {
                    this.dom.recordsContent.innerHTML = '<div class="empty-records">No records yet.</div>';
                } else {
                    const sortedRecords = [...records].sort((a, b) => a - b); // Sorts oldest to newest
                    const recordElements = sortedRecords.map((timestamp, index) => {
                        const row = document.createElement('div');
                        row.className = 'record-item';
                        row.dataset.timestamp = String(timestamp);

                        const number = document.createElement('span');
                        number.className = 'record-number';
                        number.textContent = `${index + 1}.`;

                        const dateTime = document.createElement('span');
                        dateTime.className = 'record-datetime';
                        dateTime.textContent = this.formatDateTime(timestamp);

                        const action = document.createElement('button');
                        action.className = 'record-entry-action-btn';
                        action.dataset.timestamp = String(timestamp);
                        action.setAttribute('aria-label', `Edit or delete record ${index + 1}`);
                        action.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" aria-hidden="true"><path d="M12 8c1.1 0 2-.9 2-2s-.9-2-2-2-2 .9-2 2 .9 2 2 2zm0 2c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm0 6c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2z" fill="currentColor"/></svg>';

                        row.append(number, dateTime, action);
                        return row;
                    });
                    this.dom.recordsContent.replaceChildren(...recordElements);

                    this.dom.recordsContent.querySelectorAll('.record-entry-action-btn').forEach(btn => {
                        btn.addEventListener('click', (e) => {
                            e.stopPropagation();
                            const ts = parseInt(btn.dataset.timestamp);
                            this.prepareRecordEntryModal(ts);
                        });
                    });
                    if (this.recordsScreenActive()) {
                        // Scroll to bottom is usually for newest entries at the bottom.
                        // Since we are numbering oldest (1) at top, new entries will naturally appear at the bottom.
                        // If the list is very long, the user might want to see the newest entries first,
                        // but the current request is for chronological numbering from oldest.
                        // So, scrolling to top might be more intuitive if the list is longer than the viewport.
                        // For now, let's keep the scroll to bottom as it was, assuming new entries are added and user might want to see them.
                        // Or, perhaps no explicit scroll is needed if the list isn't expected to be extremely long.
                        // Let's try scrolling to the top to see the #1 record if the list is long.
                        // setTimeout(() => { this.dom.recordsContent.scrollTop = 0; }, 0);
                        // Reverting to original: scroll to bottom to see most recent if list overflows
                         setTimeout(() => { this.dom.recordsContent.scrollTop = this.dom.recordsContent.scrollHeight; }, 0);
                    }
                }
            }


            getTimeSinceLastDose(med) {
                if (!med.records || med.records.length === 0) return Infinity;
                return Date.now() - Math.max(...med.records);
            }
            getTimeUntilNextDose(med) { return getMedicationTiming(med).remainingMilliseconds; }
            isSafeToConsume(med) { return getMedicationTiming(med).ready; }
            getProgressRatio(med) { return getMedicationTiming(med).progress; }

            getCardColor(medication, timing = getMedicationTiming(medication)) {
                if (timing.ready) {
                    return `linear-gradient(135deg, var(--safe-gradient-start) 0%, var(--safe-gradient-end) 100%)`;
                }
                const progress = timing.progress;
                const rO = 230, gO = 81, bO = 0;   // Orange
                const rG = 46, gG = 125, bG = 50;  // Green
                const r = Math.round(rO + (rG - rO) * progress);
                const g = Math.round(gO + (gG - gO) * progress);
                const b = Math.round(bO + (bG - bO) * progress);
                return `rgb(${r}, ${g}, ${b})`;
            }

            formatDuration(ms) {
                if (ms === Infinity) return 'N/A';
                const s = Math.floor(ms / 1000);
                const h = Math.floor(s / 3600);
                const m = Math.floor((s % 3600) / 60);
                if (h > 0) return `${h}h ${m}m`;
                if (m > 0) return `${m}m ${s % 60}s`;
                return `${s % 60}s`;
            }

            formatDateTime(ts) {
                const date = new Date(ts);
                return date.toLocaleDateString(undefined, {
                    weekday: 'short', month: 'short', day: 'numeric', year: 'numeric',
                    hour: 'numeric', minute: '2-digit', hour12: true
                });
            }

            setupItemSwipeGestures(element, medication) {
                if (element.hasClickActionAttached) return;
                element.hasClickActionAttached = true;

                element.addEventListener('click', (e) => {
                    if (window.getSelection().toString()) {
                        return;
                    }
                    e.stopPropagation();
                    this.showActionChoiceModal(medication);
                });
                element.addEventListener('keydown', (event) => {
                    if (event.key === 'Enter' || event.key === ' ') {
                        event.preventDefault();
                        this.showActionChoiceModal(medication);
                    }
                });
            }


            renderMedications() {
                if (this.isScreenTransitioning) return;
                const container = this.dom.medicationsList;
                if (this.medications.length === 0) {
                    container.innerHTML = `<div class="empty-records"><p>No medications added yet.</p><p style="font-size: 14px; margin-top: 8px;">Tap an action below to start.</p></div>`;
                    return;
                }
                const medicationElements = this.medications.map(med => {
                    const timing = getMedicationTiming(med);
                    const statusText = timing.ready
                        ? 'Entered wait limits cleared'
                        : `Wait limits clear in: ${this.formatDuration(timing.remainingMilliseconds)}`;
                    let lastConsumedText = 'Last: Never';
                    if (med.records && med.records.length > 0) {
                        const lastRecordTimestamp = Math.max(...med.records);
                        lastConsumedText = `Last: ${this.formatDateTime(lastRecordTimestamp)}`;
                    }
                    const item = document.createElement('div');
                    item.className = 'medication-item';
                    item.dataset.id = med.id;
                    item.style.background = this.getCardColor(med, timing);
                    item.tabIndex = 0;
                    item.setAttribute('role', 'button');
                    item.setAttribute('aria-label', `${med.name}. ${statusText}. ${lastConsumedText}`);

                    const wrapper = document.createElement('div');
                    wrapper.className = 'medication-content-wrapper';
                    const content = document.createElement('div');
                    content.className = 'medication-content';

                    const medicationName = document.createElement('div');
                    medicationName.className = 'medication-name';
                    medicationName.textContent = med.name;
                    const medicationStatus = document.createElement('div');
                    medicationStatus.className = 'medication-status';
                    medicationStatus.textContent = statusText;
                    const lastConsumed = document.createElement('div');
                    lastConsumed.className = 'medication-last-consumed';
                    lastConsumed.textContent = lastConsumedText;

                    content.append(medicationName, medicationStatus, lastConsumed);
                    wrapper.append(content);
                    item.append(wrapper);
                    return item;
                });
                container.replaceChildren(...medicationElements);
                container.querySelectorAll('.medication-item').forEach(item => {
                    const med = this.medications.find(m => m.id === item.dataset.id);
                    if (med) this.setupItemSwipeGestures(item, med);
                });
            }

            saveAndRender() {
                this.saveMedications();
                this.renderMedications();
                if (this.currentRecordsMedication && this.dom.recordsScreen.classList.contains('active')) {
                    const updatedCurrentMed = this.medications.find(m => m.id === this.currentRecordsMedication.id);
                    if (updatedCurrentMed) {
                        this.currentRecordsMedication = updatedCurrentMed;
                        this.dom.recordsTitle.textContent = this.currentRecordsMedication.name;
                    } else {
                        this.hideRecords();
                        return;
                    }
                    this.updateRecordsDisplay();
                }
            }

            showAddModal() { this.prepareAddModal(); }
            hideAddModal() { this.hideMedicationModal(); }


            showToast(message) {
                if (this.toastTimeout) clearTimeout(this.toastTimeout);
                this.dom.toast.textContent = message;
                this.dom.toast.classList.add('active');
                this.toastTimeout = setTimeout(() => this.dom.toast.classList.remove('active'), 2800);
            }
            loadMedications() {
                try {
                    const saved = JSON.parse(localStorage.getItem('medications') || '[]');
                    return parseMedicationBackup(saved);
                } catch (error) {
                    console.error('Could not read saved medication data:', error);
                    return [];
                }
            }

            saveMedications() {
                try {
                    localStorage.setItem('medications', JSON.stringify(this.medications));
                } catch (error) {
                    console.error('Could not save medication data:', error);
                    this.showToast('Could not save your changes. Storage may be full.');
                }
            }
        }

        const tracker = new MedicationTracker();

        let lastTouchEnd = 0;
        document.addEventListener('touchend', function (event) {
            const now = Date.now();
            if (now - lastTouchEnd <= 300) event.preventDefault();
            lastTouchEnd = now;
        }, { passive: false });

        if ('serviceWorker' in navigator) {
            navigator.serviceWorker.register('sw.js')
                .then(registration => {
                    console.log('Service Worker registered successfully with scope:', registration.scope);
                })
                .catch(error => {
                    console.warn('Service Worker registration failed:', error);
                });
        }
