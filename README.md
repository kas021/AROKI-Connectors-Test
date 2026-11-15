# AROKI Connectors — TEST

**This is a test feed, not the official AROKI source list.** It exists so that modules
needing the next app version can be tried by the owner and testers without affecting
people on the released app (2.1.36).

- **Who it is for:** the owner and named testers only. Do not add it to your everyday app.
- **What is in it:** AniKoto 0.3.13 and AniPM 0.1.3 (byte-identical to the live official files),
  plus two test candidates: Synthetiq Flux 0.1.6 and Synthetiq Anime 0.1.4, which add genres, year and
  status to title cards so Find a niche can filter them. The live official versions are 0.1.5 and 0.1.3.
  Everything is signed with a separate test key.
- **Repository ID:** `aroki-connectors-test`. Signing key: this feed has its own key,
  different from the official collection.

## Add it in the app
Profile → Sources → Add verified repository → enter `kas021/AROKI-Connectors-Test` → Add verified
sources → check the repository name says "AROKI Connectors — TEST" and note the key fingerprint.

## Important: modules with the same ID as official ones
A module (its family ID) can only belong to one repository on a device. If an official module
such as AniKoto is already installed, it stays owned by the official collection and this feed
cannot install or update it (the app rejects a repository-ownership change). Remove the module
first if you want to test this feed's copy, and remove it again before going back to official.

## Maintainers
`scripts/sign-and-index.sh <private-key-file> <vireo-tool>` re-signs and rebuilds `index.json`
locally from `source/*.json`. The private key lives outside this repository and is never committed.
No GitHub secrets or workflows are used. Availability depends on third-party sources; no guarantee.
