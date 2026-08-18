import assert from 'node:assert/strict';
import test from 'node:test';

import { parseMedicationBackup } from '../data.js';

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
