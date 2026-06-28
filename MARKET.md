# CubeNotch Market Research

*Research date: June 2026. Sources: WCA, Reddit, Similarweb, App Store, speedsolving.com, Hacker News, Indie Hackers.*

---

## 1. Community Size

### World Cube Association (WCA)

As of early 2026, over **282,000 people** have competed in at least one official WCA competition, across more than 16,600 competitions held globally. This is the hard floor of "serious" speedcubers — people committed enough to travel to and compete in official events. The number grows steadily each year and is skewed heavily toward Asia (China especially) and Europe, with North America as a solid third.

WCA registered competitors are not the full picture. The overwhelming majority of speedcubers never compete officially. The true hobbyist base is a much larger multiple of this number.

### Reddit

- **r/Cubers**: ~175,000 members (as of mid-2026), growing at roughly +16,000/year (+10% annually). This is the primary English-language speedcubing community online.
- **r/Rubiks**: Smaller, more casual audience, primarily beginners.

r/Cubers skews toward active hobbyists and improvers — exactly the audience for an algorithm reference and training tool.

### YouTube

- **JPerm** (J Perm / Dylan Wang): ~1.82 million subscribers. The dominant English-language speedcubing educator. His tutorials on OLL, PLL, F2L, and CFOP are the primary on-ramp for intermediate cubers.
- **CubeSkills** (Feliks Zemdegs): Primarily free tutorial content. Feliks is the most decorated competitor in history; his brand carries significant credibility among serious speedcubers.
- **GAN Cube, SpeedCubeShop**: Manufacturer/retail channels with substantial followings.
- csTimer (cstimer.net) holds the **#44,055 global rank** on Similarweb, suggesting meaningful organic traffic from the dedicated cubing audience.

### Discord

- The main Cubers Discord server: ~19,000 members. Several other servers (CubingPanda, Cubing Nation, Cuboss) collectively add thousands more.

### Honest Assessment of Community Size

Speedcubing is **a niche hobby with a meaningful digital footprint**. The 175K r/Cubers members, 1.82M JPerm subscribers, and 282K WCA competitors together suggest an addressable hobbyist population in the **low millions globally** — but the subset who use Mac desktops *and* are serious enough about CFOP to pay for an algorithm tool is substantially smaller. Rough estimate: Mac-using serious speedcubers in English-speaking markets is likely **50,000–150,000 people**. This is a niche, not a mass market.

---

## 2. Existing Competing Mac Apps

### Mac App Store: What Exists

The Mac App Store has several speedcubing timer apps, but none that combine a HUD overlay with a native algorithm library. What's available:

| App | Platform | Price | Rating | Notes |
|-----|----------|-------|--------|-------|
| **CubeTime** | iOS/iPadOS (M1 Mac via Catalyst) | Free | 4.7★ (302 ratings) | Most polished mobile timer. Uses official WCA scrambler. Not a native Mac app — runs via Catalyst. Strong community reputation. |
| **Cube Timer (Cubee)** | iOS/M1 Mac | Free | N/A | Basic two-mode timer. Simple and clean. |
| **SpeedCube Timer App** | iOS/M1 Mac | Free | N/A | Official WCA scrambles, 3D visualizer, basic stats. Very recent. |
| **Cutimer: Magic Cube Timer** | iOS/M1 Mac | Free | N/A | Claimed to be designed by 12 WCA competitors. WCA competition mode. |

**Critical observation**: Every Mac-available speedcubing app is an iOS app running via Apple Silicon compatibility. There is no native macOS app built for the Mac experience — no menu bar integration, no floating HUD overlay, no window management designed for desktop use. This is a genuine gap.

### Web-Based Competition (the real competitors)

Most serious speedcubers on desktop use web-based tools:

- **csTimer** (cstimer.net): The dominant timer among serious cubers. Free, browser-based, extremely feature-rich (all WCA events, training modes, statistics, cloud sync). It is ugly and has a steep learning curve, but its depth makes it the default for competitive cubers. Global rank ~#44,000 — significant traffic for a niche tool.
- **CubeDesk** (cubedesk.io): Modern web/former desktop app with timer, algorithm trainer, 1v1 mode, leaderboards. Started as a paid desktop app ($4.99), now free with optional Pro tier. Accumulated "tens of thousands of users." Pivoted from Electron desktop app to web to scale faster.
- **SpeedCubeDB** (speedcubedb.com): Algorithm database (see Section 3). Not a timer.
- **algdb.net**: Older algorithm database, frequently referenced but less maintained.
- **Cubeast**: Subscription-based app for Bluetooth smart cubes, focused on detailed solve analysis. Premium tier behind paywall, targets a more hardware-dependent use case.

### What CubeNotch Would Compete Against

The HUD overlay mode has **no direct competitor**. The closest thing is keeping a browser tab open to SpeedCubeDB or algdb.net while practicing on csTimer in another tab — a clunky workflow that CubeNotch's overlay directly improves.

The Library mode would compete with SpeedCubeDB, algdb.net, and the algorithm section of csTimer — all web-based, none native Mac.

---

## 3. SpeedCubeDB

### What It Is

SpeedCubeDB (speedcubedb.com) is a **free, web-based algorithm and reconstruction database** created by Gil Zussman. It covers every algorithm set for 2x2–6x6, Square-1, Pyraminx, Megaminx, and all CFOP subsets (OLL, PLL, F2L, ZBLL, COLL, etc.). It is community-validated — algorithms are submitted and automatically validated before being added, making it self-sustaining. It also includes a built-in algorithm trainer and PDF export, and a practice timer.

### Traffic Data (Similarweb, May 2026)

- **~147,000 monthly visits**
- **Global rank**: ~#117,000 (improved from earlier ~#284,000 — growing)
- **Bounce rate**: 43%
- **Pages per visit**: 7.47
- **Average session duration**: 1 min 52 sec
- **Top competitors by similarity**: cstimer.net, jperm.net, worldcubeassociation.org, cubeskills.com

The 7.47 pages per visit and nearly 2-minute sessions suggest engaged, purposeful use — people actually looking up algorithms, not casual browsers. 147K monthly visits is meaningful for a niche tool.

### Community Reception

SpeedCubeDB is widely respected in the speedcubing community as a reference. It is frequently linked in r/Cubers and speedsolving.com when algorithm questions come up. Its weaknesses are well-known: it is browser-only, requires internet connection, has no Mac-native experience, and while functional is not particularly polished as a desktop experience.

### Is There Demand for a Native Mac Version?

Direct evidence of users *asking* for a native Mac version is hard to surface from web search alone, but the signals are clear:

1. The consistent traffic to SpeedCubeDB from desktop browsers (the pages-per-visit metric implies desktop-style browsing) shows that serious cubers already use it this way.
2. The gap in the Mac App Store — no native algorithm library exists — is visible.
3. The pain point of alt-tabbing between a timer and an algorithm reference while practicing is real and frequently discussed in cubing communities (Dan's Cubing Cheat Sheet App was built specifically to solve the "messy paper cheat sheets" and scattered references problem).
4. The offline use case (practicing without reliable internet) is real for competition prep.

The demand exists implicitly. The question is whether it's strong enough to support paid software.

---

## 4. Community Pain Points

Based on forum research across r/Cubers, speedsolving.com, and related communities:

### Algorithm Reference Is Fragmented

The algorithm resource landscape is genuinely scattered. There is no single authoritative offline-capable destination. Resources referenced by the community include: SpeedCubeDB, algdb.net, JPerm's website (jperm.net), badmephisto's old site, individual algorithm pages on speedsolving.com wiki, and printed PDF sheets. Dan's Cubing Cheat Sheet App was created explicitly because the creator "got tired of flipping through printed algorithm sheets." This fragmentation is a real pain.

### Switching Between Timer and Reference Is Friction

The current workflow for many cubers practicing with csTimer or similar is: solve → check time → alt-tab to SpeedCubeDB or algdb.net → find the case → memorize → alt-tab back. A floating overlay that shows the relevant algorithm without leaving the timer is a genuine quality-of-life improvement.

### csTimer's Interface Is Dense and Dated

csTimer is the dominant tool but it is widely acknowledged to be complex and not beginner-friendly. Multiple discussions on speedsolving.com note that people use it because of its feature depth, not its usability. CubeDesk was built in direct response to csTimer's UX shortcomings and gained "tens of thousands of users" partly on this basis.

### Mac Users Are Underserved

The Mac App Store speedcubing category is thin. Every app there is an iOS port. Mac users currently rely entirely on browser-based tools, meaning they get no desktop integration, no persistent HUD, no system-level features (keyboard shortcuts, menu bar, notifications, offline caching).

### Offline Algorithm Access

Competition prep often happens in environments with unreliable wifi (hotel rooms, competition venues). A native Mac app with a local algorithm database has a clear advantage over browser-based tools.

### Advanced Algorithm Sets Are Hard to Practice

ZBLL (493 cases), COLL, and other advanced sets are poorly served by most training tools. Serious advanced cubers looking to learn these sets have limited, scattered options. A well-designed trainer for these sets would serve a small but highly motivated segment.

---

## 5. Monetization Models

### What Works for Niche Mac Utilities

Research from indie Mac developer communities (Hacker News, Indie Hackers) and pricing analysis points to consistent findings:

**One-time purchase is generally preferred by users of niche utility apps.** The utility nature of the product — it does a specific job, does not require continuous server-side updates — makes a one-time price feel fair. Subscription fatigue is real and well-documented.

**Freemium with paid unlock is the most effective model for niche utilities** because it eliminates the friction of paying before trying, allows the app to demonstrate value, and converts the subset of users who become reliant on the tool.

**Realistic price points for a niche Mac utility of this type:**
- Free tier: basic timer, basic scrambler, limited algorithm sets (OLL/PLL only)
- One-time Pro unlock: **$7.99–$12.99** — covers full algorithm library (ZBLL, COLL, F2L advanced, etc.), HUD overlay, advanced stats
- A $9.99 price point is well within the "impulse buy" range for a hobbyist who uses the tool daily

Subscription at $1.99–$2.99/month could work but is harder to justify for a utility with static content (algorithms don't change). A one-time purchase is more defensible here.

**For comparison:**
- CubeDesk started at $4.99, went free (likely could not sustain paid model against free web alternatives)
- CubeTime is free (iOS/Mac) — competing with free is necessary to get installs; the paid unlock model avoids direct free-vs-free competition
- Comparable niche Mac utilities (DevUtils, Lunar, etc.) typically charge $9.99–$19.99 one-time or $1.99–$3.99/month subscriptions and generate $3,500–$9,000/month

### Recommended Model for CubeNotch

**Freemium + one-time Pro purchase at $9.99.**

- Free: timer, WCA-compliant scrambler, OLL/PLL reference, basic stats
- Pro ($9.99 one-time): full algorithm library (F2L, ZBLL, COLL, all advanced sets), HUD overlay mode, offline access, custom algorithm slots
- Optional: a "tip jar" or "support development" option at $4.99 for users who want to contribute without needing Pro features

Avoid subscription for v1. It adds complexity, requires more trust, and is hard to justify for algorithm content that doesn't change. Revisit after building an audience.

---

## 6. Distribution

### Mac App Store

**Pros:**
- Discovery: ~40% of Mac users find apps through App Store search. For a niche like "speedcubing timer" with almost no competition, ranking #1 is achievable.
- Trust: Users trust App Store purchases; no "unverified developer" friction.
- Built-in billing, refunds, and subscription management.
- Apple covers international tax complexity.

**Cons:**
- 30% commission (15% for developers earning under $1M/year via Small Business Program).
- App Review can delay updates by days to weeks.
- Sandboxing restrictions may limit HUD overlay/window management features — the always-on-top floating panel is a common App Review pain point.
- No paid upgrades (v1 to v2) natively supported — awkward for future pricing changes.

**Critical concern**: The HUD overlay (always-on-top, borderless, floating panel over other apps) may face App Review scrutiny. Some window-management apps have had difficulty with sandboxing requirements. This needs technical validation before committing to MAS as primary distribution.

### Direct Distribution (Gumroad, Paddle, own site)

**Pros:**
- 5–10% commission vs. Apple's 30%.
- No review process — ship when ready.
- Full control over pricing, upgrade paths, licensing.
- Can offer trials, discount codes, bundle deals.

**Cons:**
- Users see "unverified developer" dialog on first launch — estimated 15–20% drop-off at this step.
- Developer is responsible for payment processing, VAT/sales tax (Paddle handles this; Gumroad does not fully).
- No organic App Store discovery.
- Requires more active marketing to drive traffic.

### Recommendation

**Dual distribution: Mac App Store as primary, direct (via Paddle or Gumroad) as secondary.**

Start with the App Store for discovery and trust. If the HUD overlay creates App Review issues, release the advanced overlay features only through direct distribution. Many indie Mac developers successfully maintain both channels.

Use the App Store version as the free tier with IAP for Pro unlock. Use direct distribution for a DMG that can be distributed via Reddit posts, Discord, and influencer links.

---

## 7. Marketing Channels

### What Works in the Speedcubing Community

**Reddit (r/Cubers)** is the highest-leverage channel for initial launch. A "Show r/Cubers" post of a polished demo (short screen recording of the HUD overlay in action during a csTimer session) can generate significant organic interest. CubeDesk gained its initial user base this way. The community responds well to tools built by fellow cubers and to clear demonstrations of solving a real workflow problem.

**YouTube** is the dominant discovery channel for cubing content but is expensive to access via sponsorship. JPerm (1.82M subscribers) charges sponsorship rates consistent with his tier — likely $3,000–$8,000 per integration based on standard YouTube influencer pricing. Smaller cubing YouTubers (10K–100K subscribers) are more accessible and may accept product-for-promotion deals or lower-cost sponsorships.

**Discord**: The main Cubers server (19K members) and related servers are active communities where new tools get shared and discussed. A launch announcement in relevant channels can drive early adoption.

**speedsolving.com forums**: The dedicated "software" and "new tool" threads have an audience of serious competitive cubers — exactly the advanced users who would care about ZBLL trainers, COLL references, and HUD overlays.

**Organic App Store search**: With minimal competition for terms like "speedcubing timer mac," "OLL PLL algorithm," and "cube timer macOS," ASO (App Store Optimization) can drive meaningful organic installs at zero cost.

**Content marketing / SEO**: Creating a landing page targeting searches like "OLL algorithms for Mac" or "csTimer overlay" could capture intent-based traffic from serious cubers.

### Influencer Landscape

- **JPerm**: The obvious target. Expensive, but a single sponsored video to 1.82M subscribers (even with low conversion) could generate hundreds of downloads.
- **Smaller cubing YouTubers** (50K–300K subscribers): More accessible; community-feel endorsements from known cubers carry weight.
- **WCA competitors with social presence**: Well-known competitive cubers who post on TikTok and Instagram can reach younger audiences.

Note: JPerm's primary sponsorship is SpeedCubeShop (cube retailer), suggesting his audience overlaps with hardware buyers. A software tool sponsorship would be a distinct category.

---

## 8. Honest Potential Assessment

### What the Numbers Suggest

The addressable market is real but small. Key constraints:

1. **Mac users are a subset of speedcubers.** Speedcubing skews young and international. Mac market share among teenagers (the core demographic) is lower than in professional/adult markets. Estimate: maybe 20–30% of active English-speaking speedcubers use Macs regularly.

2. **Serious hobbyists are a subset of Mac-using speedcubers.** Casual cubers who solved it once do not need an algorithm HUD or ZBLL trainer. The target users are people who already know CFOP basics and are actively improving — probably sub-20-second solvers and faster.

3. **Willingness to pay is uncertain.** The incumbent tools (csTimer, SpeedCubeDB) are free. CubeDesk abandoned paid pricing. Getting hobbyists to pay for a hobby tool requires demonstrating clear, daily-use value. The HUD overlay is the most differentiated feature and the strongest conversion driver — it solves a problem free tools cannot.

4. **The market is global but English-content-heavy.** Asia dominates WCA registrations but speedcubing content in English is primarily consumed by North America, Europe, and English-speaking Asia. This limits the immediate addressable market somewhat.

### Revenue Modeling

Assumptions:
- Active Mac-using serious speedcubers in English-speaking markets: 50,000–150,000
- App download rate (free tier, 12 months post-launch with moderate marketing): 3,000–8,000 downloads
- Free-to-Pro conversion rate (industry norm for niche utilities): 8–15%
- Pro price: $9.99

**Conservative scenario**: 3,000 downloads × 8% conversion × $9.99 × 0.85 (Apple cut) = **~$2,040**
**Moderate scenario**: 6,000 downloads × 12% conversion × $9.99 × 0.85 = **~$6,114**
**Optimistic scenario (JPerm feature or viral Reddit post)**: 12,000 downloads × 15% conversion × $9.99 × 0.85 = **~$15,285**

These are first-year one-time revenue figures. Annual recurring revenue requires either subscription pricing (difficult) or continued new-user acquisition.

**Realistic ceiling for a sustained solo product**: $10,000–$30,000 in the first two years, assuming the app gets featured on r/Cubers and perhaps one mid-size YouTube placement. This is meaningful side-project income, not a full-time business.

To reach $50,000+/year would require either a JPerm feature + strong conversion, expansion to iOS (much larger market), or a subscription model with a meaningful retained user base — none of which are guaranteed.

### The Honest Bottom Line

CubeNotch addresses **a real gap** — no native Mac app exists that combines a timer, algorithm library, and HUD overlay. The speedcubing community is engaged, vocal about their tools, and discoverable through clear channels (r/Cubers, JPerm, speedsolving.com).

However, this is a **niche within a niche within a niche**: Mac users, who are speedcubers, who are serious enough about CFOP to want an algorithm overlay. The commercial ceiling is modest — think "profitable side project" not "standalone business." The free incumbent tools (csTimer, SpeedCubeDB) lower willingness to pay, and the most advanced users who most need ZBLL/COLL references are also the most likely to have already set up their own workflows.

**The strongest commercial argument** is the HUD overlay mode, which no existing tool offers in a polished native Mac form. If you can make csTimer practice meaningfully better for intermediate cubers (say, 10–30 second average solvers learning advanced algorithms), you have a genuine daily-use product that justifies $9.99.

**The Library mode alone** is harder to monetize — SpeedCubeDB is free and well-maintained. The library needs to be dramatically better (offline-first, smarter trainer, superior UX) to justify charging for it.

**Build the HUD first.** It is the differentiated product. Use the library as a free tier driver. Price the full package at $9.99 one-time. Launch on r/Cubers. Target a JPerm mention within six months.

---

## Summary Table

| Dimension | Finding |
|-----------|---------|
| WCA registered competitors | 282,000+ globally |
| r/Cubers members | ~175,000 |
| JPerm YouTube subscribers | ~1.82 million |
| SpeedCubeDB monthly visits | ~147,000 |
| Main Discord server | ~19,000 members |
| Mac App Store competition | Thin — only iOS ports, no native Mac speedcubing app |
| HUD overlay competitors | None |
| Algorithm library competitors | SpeedCubeDB (free, web), algdb.net (free, web) |
| Recommended price | $9.99 one-time Pro unlock, free tier for basics |
| Recommended distribution | Mac App Store primary, direct secondary |
| Best marketing channel | r/Cubers Reddit post, then JPerm/mid-tier YouTube |
| Realistic Y1 revenue | $2,000–$15,000 depending on marketing success |
| Realistic revenue ceiling | $10,000–$30,000 over 2 years as a side project |
| Commercial potential | Real but modest — niche side project, not a business |
