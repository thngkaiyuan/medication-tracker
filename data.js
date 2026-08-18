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
        if (!Number.isInteger(maxDosesPerDay) || maxDosesPerDay < 0 || maxDosesPerDay > 24) {
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

export function getMedicationTiming(medication, now = Date.now()) {
    const records = Array.isArray(medication.records)
        ? medication.records.filter(Number.isFinite)
        : [];
    const lastDose = records.length > 0 ? Math.max(...records) : null;
    const intervalEnd = lastDose === null
        ? now
        : lastDose + (Number(medication.timeBetweenHours) * 3_600_000);

    const dailyLimit = Number(medication.maxDosesPerDay) || 0;
    const rollingDayStart = now - (24 * 3_600_000);
    const dosesInLast24Hours = records
        .filter((timestamp) => timestamp > rollingDayStart && timestamp <= now)
        .sort((left, right) => left - right);
    const dailyLimitReached = dailyLimit > 0 && dosesInLast24Hours.length >= dailyLimit;
    const dailyLimitEnd = dailyLimitReached
        ? dosesInLast24Hours[dosesInLast24Hours.length - dailyLimit] + (24 * 3_600_000)
        : now;
    const waitEnd = Math.max(intervalEnd, dailyLimitEnd);
    const remainingMilliseconds = Math.max(0, waitEnd - now);

    let progress = 1;
    if (remainingMilliseconds > 0 && lastDose !== null && waitEnd > lastDose) {
        progress = Math.min(1, Math.max(0, (now - lastDose) / (waitEnd - lastDose)));
    }

    return {
        dailyLimitReached,
        dosesInLast24Hours: dosesInLast24Hours.length,
        progress,
        ready: remainingMilliseconds === 0,
        remainingMilliseconds,
        waitEnd
    };
}
