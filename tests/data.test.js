import assert from 'node:assert/strict';
import test from 'node:test';

import { getMedicationTiming, parseMedicationBackup } from '../data.js';

test('accepts and normalizes a valid medication backup', () => {
    const result = parseMedicationBackup([{
        id: 123,
        name: '  Vitamin D  ',
        timeBetweenHours: '24',
        maxDosesPerDay: '1',
        records: [1_700_000_000_000]
    }]);

    assert.deepEqual(result, [{
        id: '123',
        name: 'Vitamin D',
        timeBetweenHours: 24,
        maxDosesPerDay: 1,
        records: [1_700_000_000_000]
    }]);
});

test('rejects malformed medication records', () => {
    assert.throws(
        () => parseMedicationBackup([{ id: '1', name: 'Test', timeBetweenHours: 4, records: ['yesterday'] }]),
        /invalid dose records/
    );
});

test('rejects backups that are not medication lists', () => {
    assert.throws(() => parseMedicationBackup({}), /expected a medication list/);
});

test('clears the wait only after both the interval and rolling 24-hour limit', () => {
    const now = new Date(2026, 7, 18, 12, 0, 0).getTime();
    const medication = {
        name: 'Example',
        timeBetweenHours: 1,
        maxDosesPerDay: 2,
        records: [
            new Date(2026, 7, 18, 8, 0, 0).getTime(),
            new Date(2026, 7, 18, 10, 0, 0).getTime()
        ]
    };

    const timing = getMedicationTiming(medication, now);
    const firstDoseClears = new Date(2026, 7, 19, 8, 0, 0).getTime();
    assert.equal(timing.ready, false);
    assert.equal(timing.dailyLimitReached, true);
    assert.equal(timing.waitEnd, firstDoseClears);
    assert.equal(timing.remainingMilliseconds, 20 * 3_600_000);
});

test('ignores future records when counting the entered daily limit', () => {
    const now = new Date(2026, 7, 18, 12, 0, 0).getTime();
    const timing = getMedicationTiming({
        name: 'Example',
        timeBetweenHours: 1,
        maxDosesPerDay: 2,
        records: [
            new Date(2026, 7, 18, 8, 0, 0).getTime(),
            new Date(2026, 7, 18, 18, 0, 0).getTime()
        ]
    }, now);

    assert.equal(timing.dosesInLast24Hours, 1);
});
