# Incremental Chronicles
 Incremental Chronicles is a strategic, text-based incremental idle game where every reincarnation shapes your destiny. Progress through tiered areas, upgrade your stats, and uncover hidden lore created with the assistence of AI. Choose between pushing forward or accepting early reincarnation for powerful bonuses that carry over to future runs. Convert repeated actions into permanent traits like Wisdom and Perception, making each reincarnation more powerful. Align with factions, interact with evolving NPCs, and face increasingly complex challenges. Will you ascend, conquer, or unite the kingdom? Your legacy is in your hands — every choice matters in this ever-evolving journey.


### **How to play:**  
1. Download the project by pressing the **code** button at the top right
2. Open the project in Godot
3. Start the game by pressing **play** in the godot editor.



### **1. High-Level Concept**  
- **Game Name** – Incremental Chronicles  
- **Genre** – Text-based incremental idle game  
- **Target Audience** – Mature audience, fans of incremental idle games  
- **Unique Selling Points (USP)** – Incremental Chronicles combines strategic reincarnation mechanics with storylines created with AI assistance. Each run will be shaped by choices made in previous runs.

---

### **2. Clear Vision Statement**  
- The player experiences satisfaction by completing many small steps in order to make the numbers go up.  
- Each area and action are crafted with the assistance of AI, but shaped trough human touch.  
- The player may influence the next reincarnation by making certain areas or encounters permanent.  

---

### **3. Core Gameplay**  
- What does the player **do**? – The player engages with the world and story trough clicking buttons in the interface. The player reads the levels of their stats and uses them to make the next decision.  
- What are the **core mechanics**?  
    - The player works to upgrade their base stats. There are permanent stats that persist after reincarnation and temporary stats that reset after reincarnation.  
    - The buttons will increase the player's temporary stats and allow resource collection. Each button provides context and flavor, adding a story line for the player to follow.  
    - As the player progresses, actions become more difficult and will eventually force the player to reincarnate after hitting the limit. The player will make it further into the game on the next reincarnation.  
    - After reincarnating once, some actions may be "upgraded". This could mean clicking it automatically as it comes up, unlocking different actions or improving the rewards it gives. This will make subsequent runs more easy, motivating the player to reincarnate. This removes the repetetive beginner actions and makes the player feel more competent and evolving.  
    - An area will provide area story points. When a player lingers in this area and keeps completing actions, the area story points build up. When a threshold is exceeded, a story ending will present itself, letting the player choose to reincarnate after this ending for a special bonus or continue exploring new areas.  
    - There are many types of actions:  
        - **Basic actions:** Provide story points for a fee or at no cost and allow the player to explore the area.  
        - **Loop actions:** Provides a reward each loop. A core element of idle gameplay 
        - **Combat actions:** The player's stats determine the success chance. After enough hits, the enemy is defeated. Combat requires resolve to engage with
        - **Reincarnate actions:** The final action of a run. This brings the player to a special area where permanent upgrades may be bought.
- How does the player win or lose? – Getting further into the game and reaching higher tiers counts as winning. Reaching the limit on an iteration will count as losing.  
- **game loop** – The player starts with low permanent and temporary stats. The player progresses through the story and tries to reach higher tiers. When the player hits the limit where an action or area becomes too difficult, the player reincarnates. During reincarnation, the player uses collected resources to upgrade permanent stats, increasing the chances of the next reincarnation.  
- What exactly triggers reincarnation? – The player chooses to reincarnate by clicking a reincarnation action. This decision is based on the current progression, collected resources, and the scale of the difficulties before them.  
- What carries over from each reincarnation:  
    - Base stats  
    - Permanent resources  
    - Unlocks
- What resets after reincarnation:  
    - Temporary stats and resources.  
    - All unlocked areas.
- What can be upgraded at reincarnation:  
    - Story point cap  
- What can be upgraded after reincarnation:  
    - Actions may be upgraded troughout the run if the player can afford it. This could mean auto-clicking or increased rewards.

---

### **4. Game World**  
- Is the world open or level-based? – The game provides tiered areas for the player to explore.  
- Describe the setting – **Medieval Fantasy Rebirth**
    - Each reincarnation, the player exits a tunnel that they don't remember entering. They see no way back into the tunnel, only out. This is where the journey begins.  
    - Each "tier" is a different region or province filled with engaging characters, corrupted creatures, and lost artifacts.  
    - Reincarnation represents the player’s desire to overcome a difficult obstacle. It's the player's wish to try again with increased opportunities.  
    - The deeper the player progresses, the more they uncover about their destiny. The player both lives in their destiny while also getting more control in shaping the destiny of their next incarnation. Ultimately, the player needs to find a path that will lead to their paradise.  

---

### **5. Characters and Story**  
- **Main characters:** – The player  
- **Story structure:** – Each area guides the player through the local story line that may include side quests. It also includes hints about the main story line. The area stories are represented by small actions that provide context and flavor. Each story and action is created with the assistance of AI to maintain consistency and variety.  
- **Dialogue:** – The player engages with NPCs one-sided — only the NPCs can talk. The player can only listen. Dialogue is displayed to the player through the buttons they use to collect temporary stats and resources.  

---

### **6. Technical Specifications**  
- **Platform:** – PC  
- **Engine:** – Godot  
- **Graphics:** – 2D text-based  
- **Controls:** – Keyboard + mouse  

---

### **7. User Interface (UI)**  
- How does the player interact with the game? – The player will use forms and buttons to interact with the game.  
- What does the HUD (Heads-Up Display) look like? – Important stats are displayed at the top or side.  
- What kind of menus and in-game feedback are shown? –  
    - Interface to spend resources on upgrading permanent and temporary stats.  
    - Interface to view current stats.  
    - Buttons to navigate the tiered areas.  
    - Buttons to progress through the story and boost temporary stats.  

---

### **10. Prototype Game Flowchart**  
- The player starts with few or no resources.  
- The player collects story points through actions in each area.  
- Some actions or areas can only be unlocked after collecting enough story points.  
- The player's story point pool has a cap that needs to be expanded after reincarnation.  
- Some actions will limit the player in other ways, such as a great danger or a large amount of required resources, forcing the player to reincarnate.  
- The player may pick an area story ending to reincarnate before hitting the limit for a special bonus, like resources or stat points.  
- The player spends collected resources to upgrade base stats and has the option to make some areas or actions permanent.  
