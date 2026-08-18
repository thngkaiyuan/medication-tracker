export function parseMedicationBackup(value) {
    if (!Array.isArray(value)) {
        throw new Error('Invalid file format: expected a medication list.');
    }

    return value.map((medication, index) => {
        const position = index + 1;
        if (!medication || typeof medication !== 'object' || Array.isArray(medication)) {
            throw new Error(`Medication ${position} is invalid.`);
        }

        const name = typeof medication.name === 'string' ? medication.name.trim() : '';
        const timeBetweenHours = Number(medication.timeBetweenHours);
        const maxDosesPerDay = medication.maxDosesPerDay ? Number(medication.maxDosesPerDay) : 0;

        if (!name) throw new Error(`Medication ${position} has no name.`);
        if (!Number.isFinite(timeBetweenHours) || timeBetweenHours < 1 || timeBetweenHours > 48) {
            throw new Error(`Medication ${position} has invalid hours between doses.`);
        }
        if (!Number.isFinite(maxDosesPerDay) || maxDosesPerDay < 0 || maxDosesPerDay > 24) {
            throw new Error(`Medication ${position} has an invalid daily dose limit.`);
        }
        if (!Array.isArray(medication.records) || medication.records.some((record) => !Number.isFinite(record))) {
            throw new Error(`Medication ${position} has invalid dose records.`);
        }

        return {
            id: String(medication.id || `${Date.now()}-${index}`),
            name,
            timeBetweenHours,
            maxDosesPerDay,
            records: [...medication.records]
        };
    });
}
