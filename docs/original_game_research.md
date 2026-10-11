# Original game research

Research date: 2026-10-11. Target: Igelsoft Mafia, fixed C64 releases, not Sascha Laffrenzen's game.

## Sources and priority

1. Fixed C64 behavior (German 1.20 / English 1.31+), when verified.
2. C64 documentation, screenshots and gameplay.
3. https://www.c64-wiki.com/wiki/Mafia (accessed 2026-10-11).
4. https://github.com/drunkeneye/MAFIA.A8 at commit 316e8da7391c5c9f65036baa0cb752a9b02e6a9d.
5. https://www.retro-gamer.de/mafia-1986-bandenkrieg-auf-dem-c64/ (accessed 2026-10-11).

The Atari source was downloaded outside the project for study. No source code, graphics, music or fonts from it are bundled. Both manuals, README, main/player/map/sprites, fight/AI/utils, helpers_game, setup, updates, variables, all location handlers, data generators and location translations were inspected. Direct play against fixed C64 releases is still required before claiming faithful C64 numerical parity.

## Findings and decisions

| Mechanic | Evidence | Decision / uncertainty |
| --- | --- | --- |
| City | C64-Wiki controls/city; Atari sprites/main | Cardinal grid movement; one step per street tile, location entry costs movement. Vehicles increase turn allowance. Original city geometry is not yet verified; use an original connected district layout temporarily. |
| Calendar | Atari player/main/setup | One single-player turn advances one month; choose 25-year/100-point or 50-year/200-point campaign. |
| Starting state | Fixed C64 BASIC 313/315/350 | One unarmed leader, energy 5; random attributes 10–50 in steps of 5 and money $5000–7000 in steps of $500. Press-to-stop attribute selection adapted to random rolls. |
| Cars | Fixed C64 BASIC 14035/50300–50305 | Prices 3000/4000/5000/6000/7000, cargo 100/120/200/150/100 (50 on foot), movement 25/35/40/40/60/35. |
| Weapons | Fixed C64 50100–50115, 13050–13070 | Restored original names, prices, precision/effect, prerequisites and trade-in. See primary-source table below. No invented ammunition economy. |
| Gang | pub; C64-Wiki | Rank 5 and rented accommodation required; maximum ten including leader. New recruits start at 5 energy. Thirty fixed C64 offers replace the provisional roster. |
| Combat | manuals; C64-Wiki; fight/utils/AI | Each side's conscious members act once, moving OR attacking OR passing. Cardinal fire stops at walls/opponents and passes allies. Zero energy incapacitates, does not kill permanently; recover between months. AI checks viable shots then approaches opponents. |
| Damage | helpers_fight source C64 BASIC comment | Original miss checks use weapon precision and strength/10+1. Use these rather than port's changed miss checks. Fixed C64 damage is floor(random × effect + brutality/10) + 1. |
| Energy | updates/doFight | Recover floor(strength/10)+1 monthly, capped at 2+floor(strength/4)+floor(brutality/4). Post-combat energy minimum 5. |
| Early jobs | pub/updates | Offered only through rank 3. Duration 1–3 months, wages 1000–3000, job-specific resolutions. Port comments change points for one job; preserve +6 for that job, +3 others pending direct C64 check. |
| Smuggling | pub; C64-Wiki | Buy at station pubs, sell elsewhere. Buy price 5–14, sell 10–29, limited by vehicle cargo; buyers not always interested. |
| Rank | updates; C64-Wiki | Port rank formula min(10, (points+5)/(goal/10)), promotions retained after points loss. Port acknowledges omitted original weighting; provisional pending fixed C64 verification. |
| Police | sprites source comments | Fixed C64 2041 checks when remaining steps are a multiple of 20, with 20% chance at rank 4+. The port comment claimed 10%, so primary BASIC takes precedence. Searches may detect counterfeits, seize alcohol or identify wanted leader without forged papers. |
| Bribery | police/sprites | HQ $1000/month protection; expires monthly and offers 50% release on arrest. Incident bribe $500+500*rank, 1/5 rejection. Escape depends on vehicle. |
| Court | sprites | Sentence 1+rank/2 months. Lawyer available above rank 4, payment reduces sentence stochastically. Court cancels tips and jobs and removes points. |
| Forgery | main comments; forgery | Forged ID costs $1000/member. Port uses fixed six-month counterfeit lifetime and 1/12 ID loss; original BASIC comments show 1/8 expiry for both. Use 1/8 monthly expiry. Counterfeit exchange quantity/pricing remain provisional. |
| Debt | loanshark/updates | Borrow up to $5000; debt principal+principal/16; deadline 6–9 months. Five armed collectors when overdue; loss wipes cash and debt, victory extends deadline. Ownable loan business/investment pays intermittently. |
| Gambling | gambling BASIC comment | Three games, win chances 1/(1+x), payouts stake*(0.5+x). Use documented C64 formula rather than changed Atari payouts. |
| Bank | bank; C64-Wiki | Robbery can trigger guards. Safe cracking is a three-wheel combination minigame with intelligence-dependent turns and audio feedback; failure triggers police. Port blocks solo safe cracking too, conflicting with wiki opening strategy. Allow solo safe cracking with appropriate rank/stats; require two gangsters for daytime robbery. |
| Store | store | Rank 2; distinct robbery, deception, burglary and fraud requirements. Repeated crime at same shop attracts police. Reward and follow-up combat depend on shop type. |
| Subway/station | subway/centralstation | $50 subway fare; pickpocket outcome depends on intelligence and station. Mail train tip and at least three gangsters required for guarded robbery. |
| Tips | pub | Rank 4, random availability, cost $1000–2500, five possibilities: train, bank gold, transport, gun-running investment, mayor. Mission markers appear only with tip. |
| Mayor | major; C64-Wiki | Five guards (20 energy, weapon 7), then mayor (30, weapon 1); $7000 and forged ID. Port explicitly adds 4 points absent original: do NOT add those points. |
| Transport | moneytransporter | At least three gangsters; ten guards, energy 50, weapon 7. Tip consumed, completion only on victory. Loot provisional from port (14000–16784), +4 points. |
| Victory | main; manuals; C64-Wiki | Required score/rank AND mayor AND transporter; money alone never wins. Time limit produces an unsuccessful ending when requirements unmet. |

## Remaining verification

Compare map, score weighting, full job outcomes, shop sublocations and transport loot against fixed C64 gameplay. The current implementation must call these provisional, not verified originals. Research decisions may be refined without altering saved definition IDs.

## Fixed C64 1.20 primary-source review (2026-10-11)

Downloaded the [C64Games Igelsoft archive](https://www.c64games.de/phpseiten/spieledetail.php?filnummer=336), extracted the HtW fixed 1.20 disk directory and detokenized `MF-PRG` in a temporary research directory. No disk code, art or audio is redistributed. This is stronger evidence than the Atari tables.

- BASIC 50100–50115: hands, knife, club, chain, throwing stars, revolver, rifle, SMG, grenades. Prices 0/50/100/500/3000/4000/4500/8000/10000; precision 2/3/4/4/2/5/5/6/7; damage factors 2/5/3/4/7/10/12/15/18. Last DATA field is sound index, **not range**.
- BASIC 30215–30216: nominal shot counter 2 for melee, 15 for ranged and 20 for rifle/SMG; decrement/termination happens before collision. Our two-character actors retain nominal distances; exact original character geometry remains a difference.
- BASIC 30226 targets opposite color only; own gang is passed through. 30247 uses the two precision/strength miss checks. 30255 damage is floor(random × effect + brutality/10) + 1. Restored these rules.
- BASIC 50300–50305: cargo 50/100/120/200/150/100; movement 25/35/40/40/60/35. 14035 prices 3000 + 1000 × (car index−1).
- BASIC 13050–13060: intelligence ≥40 for weapon index >5; strength ≥20 for club/chain; brutality ≥40 for chain/SMG/grenades. 13070 trade-in floor(price/1.5).
- `GAN1`–`GAN30` contain original names, weapons, six-digit strength/intelligence/brutality and advances. BASIC 12126 adds $1000 to listed advance. All thirty offers are now represented; 12105 limits a gang to ten. Offer selection still differs from random hotel-quality selection.
- BASIC 1000 starts 1925. HUD now starts January 1925. 313/12165 start leader/recruits at energy 5; 4015–4020 recovers floor(strength/10)+1 monthly, capped at 2+floor(strength/4)+floor(brutality/4). Restored these health rules.

This is a table/rule inspection, not a full emulated 1.20 playthrough. Exact map, rank weighting, hotel offers and remaining location details require further comparison.

Primary C64 follow-up: BASIC 2041 overrides the conflicting port police comment (20%, remaining-step multiples of 20). 2060 charges five steps for a location visit. 315/350 give $5000–7000 by $500 and attributes 10–50 by 5. These values now replace the provisional port values.
