//
//  TrailNotes.swift
//  Ascent ADHD
//
//  Micro-lesson psychoeducation cards ported from MainActivity.kt (SEED_TRAIL_NOTES + sequencing).
//

import Foundation

let TRAIL_PROMPT_QUIZ = "QUIZ"
let TRAIL_PROMPT_REFLECT = "REFLECT"
let TRAIL_STAGE_FOUNDATION = "FOUNDATION"
let TRAIL_STAGE_INMOMENT = "INMOMENT"
let TRAIL_STAGE_ANY = "ANY"

struct TrailNote: Identifiable, Hashable {
    let id: String
    let title: String
    let body: String
    let promptType: String
    let promptQuestion: String
    let promptOptions: [String]
    var correctOption: Int? = nil
    var linkAction: String? = nil
    var linkLabel: String? = nil
    var stage: String = TRAIL_STAGE_ANY
    var order: Int = 0
    var sources: [String] = []
}

let SEED_TRAIL_NOTES: [TrailNote] = [
    TrailNote(
        id: "tn_what_is_dopamine",
        title: "Your brain isn't lazy — it's under-rewarded",
        body: "ADHD brains tend to under-respond to ordinary rewards, so everyday tasks can feel flat and hard to start. This isn't a willpower problem. It's why building in clear, immediate rewards — like the ones in this app — actually helps your brain engage.",
        promptType: TRAIL_PROMPT_QUIZ,
        promptQuestion: "Why can ordinary tasks feel so hard to start?",
        promptOptions: ["You're lazy", "ADHD brains under-respond to ordinary rewards", "You don't care enough"],
        correctOption: 1, stage: TRAIL_STAGE_FOUNDATION, order: 1,
        sources: ["Volkow et al. (2010), Molecular Psychiatry — dopamine reward-pathway dysfunction in ADHD",
                  "Aarts et al. (2015), Frontiers in Human Neuroscience — striatal reward response in adult ADHD"]
    ),
    TrailNote(
        id: "tn_implementation_intentions",
        title: "Glue a task to something you already do",
        body: "Starting is the hardest part. An if-then plan — \"when I finish my coffee, I'll start the report\" — borrows momentum from a habit you already have, so the start happens almost on autopilot instead of needing a fresh decision.",
        promptType: TRAIL_PROMPT_QUIZ,
        promptQuestion: "What makes an if-then \"starter cue\" work?",
        promptOptions: ["It borrows momentum from an existing habit", "It makes the task shorter", "It adds pressure"],
        correctOption: 0, linkAction: "ADD_CUE", linkLabel: "Add a starter cue", stage: TRAIL_STAGE_ANY, order: 2,
        sources: ["Gollwitzer (1999), American Psychologist — implementation intentions",
                  "Gawrilow, Gollwitzer & Oettingen (2011), J. of Social & Clinical Psychology — if-then plans in children with ADHD"]
    ),
    TrailNote(
        id: "tn_chosen_rewards",
        title: "Pick rewards you actually want",
        body: "A reward you chose yourself motivates more than one handed to you — and it works best when it's small and comes soon after the effort. That's the whole point of your reward bank: ready-made, self-chosen treats you can attach to a task in one tap.",
        promptType: TRAIL_PROMPT_REFLECT,
        promptQuestion: "When did you last reward yourself for finishing something?",
        promptOptions: ["Today", "This week", "Can't remember"],
        linkAction: "OPEN_REWARD_BANK", linkLabel: "Edit my reward bank", stage: TRAIL_STAGE_ANY, order: 3,
        sources: ["Volkow et al. (2010), Molecular Psychiatry — why immediate reward matters in ADHD",
                  "Deci & Ryan — self-determination theory: self-chosen rewards protect motivation"]
    ),
    TrailNote(
        id: "tn_delay_aversion",
        title: "Shrink the mountain into footholds",
        body: "A big task with a far-off payoff is exactly what an ADHD brain wants to avoid. Breaking it into short timed chunks — each with its own small win — turns one aversive mountain into a series of doable footholds. That's what a focus session does.",
        promptType: TRAIL_PROMPT_QUIZ,
        promptQuestion: "Why break a task into short timed chunks?",
        promptOptions: ["To finish faster", "Each chunk is a near-term win, which is easier to start", "To track time better"],
        correctOption: 1, linkAction: "START_FOCUS", linkLabel: "Start a focus session", stage: TRAIL_STAGE_INMOMENT, order: 4,
        sources: ["Marx et al. (2021), J. of Attention Disorders — delay-discounting meta-analysis (37 comparisons)",
                  "Demurie et al. (2012), Developmental Science — steeper reward discounting in ADHD"]
    ),
    TrailNote(
        id: "tn_future_self",
        title: "Make the finish line feel real",
        body: "ADHD brains discount future rewards steeply — a payoff that's days away barely registers now. Vividly picturing the moment you finish (where you are, how it feels) pulls that future closer and makes it more motivating today.",
        promptType: TRAIL_PROMPT_REFLECT,
        promptQuestion: "Picture finishing a goal you're working on. How clearly can you see it?",
        promptOptions: ["Crystal clear", "A little fuzzy", "Haven't tried"],
        stage: TRAIL_STAGE_ANY, order: 5,
        sources: ["Sonuga-Barke & Fairchild (2012), Biological Psychiatry — delay aversion in ADHD",
                  "Barkley (2012), Executive Functions — \"temporal myopia\" (future rewards lack present salience)"]
    ),
    TrailNote(
        id: "tn_reward_novelty",
        title: "Rewards go stale — refresh them",
        body: "The same reward loses its pull over time as your brain habituates. Swapping in new rewards every few weeks keeps the novelty — and the motivation — alive. The app nudges you to refresh your bank about once a month for exactly this reason.",
        promptType: TRAIL_PROMPT_QUIZ,
        promptQuestion: "Why refresh your rewards every few weeks?",
        promptOptions: ["The brain habituates and they lose their pull", "Old rewards stop being allowed", "It's required to keep the app working"],
        correctOption: 0, stage: TRAIL_STAGE_INMOMENT, order: 6,
        sources: ["Schultz (1998), J. of Neurophysiology — dopamine reward signal & habituation",
                  "Volkow et al. (2010), Molecular Psychiatry — ADHD reward system responds to novelty"]
    ),
    TrailNote(
        id: "tn_time_blindness",
        title: "Your internal clock runs on a different battery",
        body: "Time blindness isn't carelessness — it's a documented difference in how ADHD brains process time. When the brain's timing systems are dysregulated, the future can feel distant and vague even when it's minutes away, which is why deadlines that are \"soon\" can feel unreal until they're urgent. Making time visible — clocks, timers, visual countdowns — works because it externalizes what your brain struggles to generate internally.",
        promptType: TRAIL_PROMPT_QUIZ,
        promptQuestion: "Why does an ADHD brain often lose track of time?",
        promptOptions: ["Time just moves faster for some people", "Differences in how the brain tracks duration", "ADHD brains don't care about being on time"],
        correctOption: 1, stage: TRAIL_STAGE_FOUNDATION, order: 7,
        sources: ["Barkley (2012), Executive Functions — temporal processing as a core ADHD feature",
                  "Doyle (2006), review — time perception among ADHD executive-function impairments"]
    ),
    TrailNote(
        id: "tn_task_switching",
        title: "Give yourself a 5-minute warning before you switch",
        body: "Every time you shift from one task to another, your brain pays a \"switch cost\" — a measurable dip in speed and accuracy while it unloads the old task and loads the new one. Research suggests ADHD brains tend to pay a larger switch cost. A simple 5-minute wind-down warning — a timer, a note, a spoken cue — gives your brain time to start disengaging before the switch lands, cutting the cost and reducing transition paralysis.",
        promptType: TRAIL_PROMPT_QUIZ,
        promptQuestion: "Why does switching tasks feel harder than it should?",
        promptOptions: ["You're avoiding the next task", "Your brain needs time to unload one task and load the next", "You haven't practiced switching enough"],
        correctOption: 1, linkAction: "START_FOCUS", linkLabel: "Start a focus session", stage: TRAIL_STAGE_INMOMENT, order: 8,
        sources: ["Cepeda, Kramer & Gonzalez de Sather (2001), Developmental Psychology — task-switch costs",
                  "Marx et al. (2015), Neuropsychologia — attentional set-shifting in adults with ADHD"]
    ),
    TrailNote(
        id: "tn_wall_of_awful",
        title: "That feeling before a hard task has a name",
        body: "ADHD coach Brendan Mahan calls it the \"Wall of Awful\" — the emotional barrier built up from years of struggling with things that were hard because of your wiring. When you go to start a task you've struggled with before, your brain doesn't just see the task — it replays the past difficulty around it. The wall isn't weakness; it's an understandable response to a history of difficulty. Naming it is the first step to finding the door through it.",
        promptType: TRAIL_PROMPT_REFLECT,
        promptQuestion: "Think of a task you've been avoiding. What comes up when you picture starting it?",
        promptOptions: ["Dread or anxiety", "Shame or embarrassment", "Numbness — I just go blank"],
        stage: TRAIL_STAGE_FOUNDATION, order: 9,
        sources: ["Brendan Mahan — the \"Wall of Awful\" (an ADHD coaching framework, not a clinical diagnosis)",
                  "Psychology Today (2025) — clinical application of the concept (Mutti-Driscoll)"]
    ),
    TrailNote(
        id: "tn_rsd",
        title: "Strong feelings about mistakes aren't a personality flaw",
        body: "Many people with ADHD feel criticism, failure, or rejection intensely and suddenly — the reaction can seem out of proportion because it's tied to how the ADHD brain regulates emotion, not to weak character. A 2023 systematic review found emotional dysregulation is common across the ADHD lifespan and a real source of difficulty. Knowing the reaction is wired in, not a flaw, makes it easier to respond rather than react.",
        promptType: TRAIL_PROMPT_REFLECT,
        promptQuestion: "When you make a mistake or get criticized, how does it usually land?",
        promptOptions: ["It stings but passes quickly", "It hits hard and lingers for hours", "It can derail my whole day"],
        stage: TRAIL_STAGE_FOUNDATION, order: 10,
        sources: ["Soler-Gutiérrez et al. (2023), systematic review — emotional dysregulation across the ADHD lifespan",
                  "Shaw et al. (2014), American J. of Psychiatry — emotional dysregulation as a core ADHD feature",
                  "Note: \"rejection sensitive dysphoria\" is a clinical-popular term (Dodson), not a formal DSM diagnosis"]
    ),
    TrailNote(
        id: "tn_body_doubling",
        title: "Someone nearby can do what willpower can't",
        body: "Body doubling — working alongside another person, even silently, even on video — is one of the most widely reported ADHD strategies for a reason. Another person's presence provides subtle external activation: light accountability, a shared attention field, and a pacing cue your brain can borrow. It draws on a well-established effect called social facilitation, where the presence of others raises arousal and helps you engage. In-person, virtual, or even a \"study with me\" video can all work.",
        promptType: TRAIL_PROMPT_QUIZ,
        promptQuestion: "Why does having someone nearby help with getting started?",
        promptOptions: ["They can help if you get stuck", "Their presence externalizes the activation your brain struggles to self-generate", "It makes the work go faster"],
        correctOption: 1, linkAction: "START_FOCUS", linkLabel: "Start a focus session", stage: TRAIL_STAGE_INMOMENT, order: 11,
        sources: ["Social facilitation research (well-established) — presence of others raises task arousal",
                  "Ara et al. (2025), preliminary VR study (preprint, n=12) — body double aided ADHD task completion"]
    ),
    TrailNote(
        id: "tn_working_memory",
        title: "Your brain can't hold it all — so don't make it",
        body: "ADHD often involves working-memory limits — the ability to hold and use information while doing something else. When working memory is stretched, details slip, you lose track of steps, and everything takes more effort. The fix isn't trying harder to remember: it's getting the information out of your head. Checklists, written steps, voice memos, and reminders act as external memory, freeing up your attention for the task itself.",
        promptType: TRAIL_PROMPT_QUIZ,
        promptQuestion: "What's the most effective way to handle working-memory gaps?",
        promptOptions: ["Practice memorizing things more", "Externalize info into lists, notes, or reminders", "Avoid complex tasks"],
        correctOption: 1, stage: TRAIL_STAGE_ANY, order: 12,
        sources: ["Gilbert et al. (2022), Psychonomic Bulletin & Review — \"intention offloading\" is highly effective",
                  "Barkley — externalizing information as a core ADHD strategy"]
    ),
    TrailNote(
        id: "tn_self_compassion",
        title: "Missing a day doesn't erase your progress",
        body: "ADHD brains are prone to all-or-nothing thinking: one missed day can feel like the whole streak — and the whole system — is broken. But research on habit formation shows a single lapse has no meaningful long-term effect if you restart promptly. What matters more is self-compassion: adults with ADHD who practice self-kindness tend to report better follow-through and lower emotional reactivity. It's not just a nice idea — it's a functional strategy.",
        promptType: TRAIL_PROMPT_REFLECT,
        promptQuestion: "When you miss a day on something you're building, what's your first reaction?",
        promptOptions: ["I restart the next day, no drama", "I feel guilty but come back eventually", "I write off the whole effort"],
        stage: TRAIL_STAGE_ANY, order: 13,
        sources: ["Lally et al. (2010), European J. of Social Psychology — one missed day doesn't break habit formation",
                  "Beaton, Sirois & Milne (2022), J. of Clinical Psychology — self-compassion & ADHD wellbeing"]
    ),
    TrailNote(
        id: "tn_sleep",
        title: "Sleep isn't optional — it's executive-function fuel",
        body: "ADHD already taxes executive function — attention, impulse control, working memory, emotional regulation. Sleep deprivation taxes the very same systems, so the two compound each other. Research shows people with ADHD traits are especially vulnerable to cognitive impairment from poor sleep, and sleep problems are common in ADHD (by some estimates affecting a majority of kids with ADHD). Protecting sleep is one of the highest-leverage things you can do for the functions ADHD already makes hard.",
        promptType: TRAIL_PROMPT_QUIZ,
        promptQuestion: "Why does poor sleep hit especially hard with ADHD?",
        promptOptions: ["ADHD brains need more sleep than other brains", "Sleep loss and ADHD tax the same executive systems, compounding the effect", "Sleep problems are unrelated to ADHD"],
        correctOption: 1, stage: TRAIL_STAGE_FOUNDATION, order: 14,
        sources: ["Liang et al. (2021), Frontiers in Pediatrics — sleep mediates physical activity → executive function in ADHD",
                  "Åkerstedt et al. (2020), Biological Psychiatry: CNNI — ADHD traits predict greater impairment after sleep loss"]
    ),
    TrailNote(
        id: "tn_hyperfocus",
        title: "Hyperfocus is a feature, not just a bug",
        body: "Hyperfocus — getting so absorbed that hours vanish — is one of ADHD's paradoxes: the same brain that can't stay on a boring task can lock onto an interesting one with extraordinary intensity. It appears linked to the same dopamine-and-interest mechanisms behind distraction: when a task is intrinsically rewarding, the system engages fully. The key is steering it on purpose. A focus session on the right task can become hyperfocus — but without an exit plan it can swallow your afternoon. Set a timer and a stopping cue before you dive in.",
        promptType: TRAIL_PROMPT_REFLECT,
        promptQuestion: "Last time you hyperfocused — was it on something useful, or did it eat your time?",
        promptOptions: ["Useful — I got a ton done", "Both — started useful, drifted", "Mostly time-eating"],
        linkAction: "START_FOCUS", linkLabel: "Start a focus session", stage: TRAIL_STAGE_ANY, order: 15,
        sources: ["Hyperfocus in ADHD (2025), European Psychiatry — 50-adult study; recommends timers & structured breaks",
                  "ADDitude — hyperfocus linked to dopamine and high-interest tasks"]
    )
]

/// Ordered sequence of notes for a journey stage (matching-stage first, ANY threaded, off-stage last).
func trailSequenceForStage(_ stage: String) -> [TrailNote] {
    func weight(_ n: TrailNote) -> Int {
        if n.stage == TRAIL_STAGE_ANY { return 1 }
        if n.stage == stage { return 0 }
        return 2
    }
    return SEED_TRAIL_NOTES.sorted {
        weight($0) != weight($1) ? weight($0) < weight($1) : $0.order < $1.order
    }
}
