# Preparedness Coach — progress and goals

Implemented: inventory-driven advice, prioritized home highlights, scenario selection, persistent action-list IDs, children/pets/regular-medication review prompts, Greek/English copy, source links. Rules run locally; there is no language model, chat, live hazard monitoring or push scheduling.

## Calculation contract
- Water: 4 L/person/day is ReadyKit's rounded storage-planning baseline derived from CDC's 1 US gallon (~3.785 L), not prescribed fluid intake. Long horizons are arithmetic extensions, not CDC recommendations to stock a year.
- Food: 2,000 kcal/person/day is a provisional software assumption, not personalized nutrition. Children are not given adult recommendations; the UI explicitly flags this as unpersonalized. Pet and extra climate/medical needs are not included.
- Quantities <= 0, expired entries and invalid numeric amounts are excluded. Missing energy/liters are explicitly flagged. Undated entries count with a caveat. Stock expiring during the target gets a rotation warning.
- Home percentage is min(water coverage, food energy coverage), labeled stock coverage. It is not overall preparedness. Other categories have no completeness percentages.
- Food cooking/refrigeration requirements and allergen notes can now be entered. Unknown remains unknown. Outage reviews flag utility-dependent foods; totals still represent stored energy, not outage-usable nutrition. Balanced nutrition, actual storage conditions and portability remain unassessed.

## Sources reviewed 2026-11-22
- CDC emergency water: https://www.cdc.gov/water-emergency/about/how-to-create-and-store-an-emergency-water-supply.html
- CDC prescriptions: https://www.cdc.gov/prepare-your-health/take-action/prescriptions.html
- CDC personal needs: https://www.cdc.gov/prepare-your-health/take-action/personal-needs.html
- USDA food choices: https://ask.fsis.usda.gov/article/What-foods-should-I-keep-in-my-house-for-emergencies
- Greek Civil Protection: https://civilprotection.gov.gr/odigies-prostasias/seismoi and /plimmyres and /dasikes-pyrkagies
Sources support general advice, not calculated user-specific gaps or the 2,000 kcal assumption.

## Verification
Run `bash scripts/test-planning.sh` on macOS. This compiles the actual calculator/advisor against a minimal model fixture and checks 28 cases. It does not validate SwiftData, SwiftUI or device behavior.
Xcode/iPhone acceptance: open Coach from Home; change people/days; confirm 4 x 30 gives 480 L and 240,000 kcal; add stock and see deficits shrink; verify expired entries excluded; select outage and evacuation; save an action and relaunch; change language; scan from both Home and dock.

## Remaining work toward the full assistant
- Personalize needs using reviewed evidence; structured allergen matching and clinician-entered prescription schedules. The current profile captures member birth years, allergy/diet notes, regular-medication flags, pets and backup utilities, but does not personalize quantities.
- Offline reviewed emergency instruction packs with before/during/after phases and versioned provenance.
- A server-side model connection, retrieval with citations, privacy controls, adversarial scenario evaluation and explicit abstention when evidence is missing. API keys must not be embedded in the iOS app.
- This first release must not be represented as a completed AI survival assistant.


## Update 2026-11-22 — inventory review and household context
- Dock moved into a real bottom safe-area inset; verify final list rows remain reachable on iPhone.
- Missing liters/calories appear before purchase advice, with direct edit links. Purchase gaps are withheld only for the affected category until its entries are complete.
- Advice details and sources collapse under an expandable row.
- Local household profile is available from Settings and Coach. Saving synchronizes people count; discrepancies after manual count changes are flagged.
- Optional food metadata preserves unknown values for old entries; outage reviews flag missing prep information and cooking/cooling dependencies.
- Profile allergy notes trigger a suitability review, not automatic safe-food certification.

Validation: Swift syntax parser and shell syntax checked in Linux. The 28 executable checks are prepared but were NOT run here (no Swift/Xcode). SwiftUI typechecking and SwiftData migration have NOT been verified.

Device acceptance still required: update the existing installation without deleting it; confirm old inventory remains; scroll to the final Coach card above the dock; edit an incomplete item and verify the appropriate gap appears only when all amounts in that category are known; save/reopen profile and food metadata; exercise outage prompts; check Greek/English. Run the planning script and build in Xcode before release.

Next milestone: reviewed offline event guidance, followed by a real sourced AI conversation with backend credentials and explicit data-sharing controls. No AI model is connected in this update.
