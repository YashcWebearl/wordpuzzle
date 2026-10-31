import 'dart:math' as math;

class BalloonPuzzle {
  final int level;
  final String word;
  final String category;
  final String emoji;
  final String clue;
  final int poolSize; // 10 or 12 letters
  final List<String> letterPool;

  const BalloonPuzzle({
    required this.level,
    required this.word,
    required this.category,
    required this.emoji,
    required this.clue,
    required this.poolSize,
    required this.letterPool,
  });
}

class BalloonLevelData {
  // ==========================================
  // TIER 1: 3-LETTER WORDS (Levels 1 - 5)
  // ==========================================
  static const List<Map<String, dynamic>> _words3 = [
    {'word': 'CAT', 'cat': 'ANIMALS', 'emoji': '🐱', 'clue': 'A furry pet that purrs'},
    {'word': 'DOG', 'cat': 'ANIMALS', 'emoji': '🐶', 'clue': 'Man\'s loyal best friend'},
    {'word': 'SUN', 'cat': 'NATURE', 'emoji': '☀️', 'clue': 'Shines bright in daytime sky'},
    {'word': 'BUS', 'cat': 'VEHICLES', 'emoji': '🚌', 'clue': 'Large vehicle for passengers'},
    {'word': 'PIG', 'cat': 'FARM', 'emoji': '🐷', 'clue': 'Pink farm animal that oinks'},
    {'word': 'COW', 'cat': 'FARM', 'emoji': '🐮', 'clue': 'Gives fresh wholesome milk'},
    {'word': 'FOX', 'cat': 'WILDLIFE', 'emoji': '🦊', 'clue': 'Clever animal with bushy tail'},
    {'word': 'OWL', 'cat': 'BIRDS', 'emoji': '🦉', 'clue': 'Wise nocturnal bird of prey'},
    {'word': 'CUP', 'cat': 'KITCHEN', 'emoji': '☕', 'clue': 'Used for drinking warm tea'},
    {'word': 'BAT', 'cat': 'NIGHT', 'emoji': '🦇', 'clue': 'Flies at night with wings'},
    {'word': 'HAT', 'cat': 'CLOTHES', 'emoji': '🎩', 'clue': 'Worn on the head for style'},
    {'word': 'ICE', 'cat': 'WINTER', 'emoji': '🧊', 'clue': 'Frozen solid cold water'},
    {'word': 'KEY', 'cat': 'OBJECTS', 'emoji': '🔑', 'clue': 'Unlocks heavy metal doors'},
    {'word': 'MAP', 'cat': 'TRAVEL', 'emoji': '🗺️', 'clue': 'Guides explorers on journeys'},
    {'word': 'NUT', 'cat': 'SNACKS', 'emoji': '🥜', 'clue': 'Hard shell snack rich in energy'},
    {'word': 'SEA', 'cat': 'NATURE', 'emoji': '🌊', 'clue': 'Large salty ocean waters'},
    {'word': 'TEA', 'cat': 'DRINKS', 'emoji': '🍵', 'clue': 'Warm aromatic brewed beverage'},
    {'word': 'VAN', 'cat': 'VEHICLES', 'emoji': '🚐', 'clue': 'Spacious delivery automobile'},
    {'word': 'BEE', 'cat': 'INSECTS', 'emoji': '🐝', 'clue': 'Makes sweet natural honey'},
    {'word': 'PIE', 'cat': 'FOOD', 'emoji': '🥧', 'clue': 'Baked sweet crust dessert'},
    {'word': 'TOY', 'cat': 'FUN', 'emoji': '🧸', 'clue': 'Playful item loved by kids'},
    {'word': 'ANT', 'cat': 'INSECTS', 'emoji': '🐜', 'clue': 'Tiny hardworking creature'},
    {'word': 'CAR', 'cat': 'VEHICLES', 'emoji': '🚗', 'clue': 'Four wheeled road transport'},
    {'word': 'ZOO', 'cat': 'PLACES', 'emoji': '🦁', 'clue': 'Park filled with wild animals'},
    {'word': 'BOX', 'cat': 'OBJECTS', 'emoji': '📦', 'clue': 'Cardboard container for gifts'},
  ];

  // ==========================================
  // TIER 2: 4-LETTER WORDS (Levels 6 - 25)
  // ==========================================
  static const List<Map<String, dynamic>> _words4 = [
    {'word': 'LION', 'cat': 'WILDLIFE', 'emoji': '🦁', 'clue': 'The fearless jungle king'},
    {'word': 'BIRD', 'cat': 'NATURE', 'emoji': '🐦', 'clue': 'Sings sweet tunes in trees'},
    {'word': 'FISH', 'cat': 'OCEAN', 'emoji': '🐟', 'clue': 'Glides underwater with fins'},
    {'word': 'STAR', 'cat': 'SPACE', 'emoji': '⭐', 'clue': 'Twinkles in nighttime sky'},
    {'word': 'MOON', 'cat': 'SPACE', 'emoji': '🌙', 'clue': 'Glows in nocturnal darkness'},
    {'word': 'FROG', 'cat': 'WILDLIFE', 'emoji': '🐸', 'clue': 'Leaps high across lily pads'},
    {'word': 'DUCK', 'cat': 'BIRDS', 'emoji': '🦆', 'clue': 'Swims and quacks in pond'},
    {'word': 'BEAR', 'cat': 'FOREST', 'emoji': '🐻', 'clue': 'Loves sweet wild honey'},
    {'word': 'WOLF', 'cat': 'FOREST', 'emoji': '🐺', 'clue': 'Howls loud at the full moon'},
    {'word': 'DEER', 'cat': 'FOREST', 'emoji': '🦌', 'clue': 'Graceful animal with antlers'},
    {'word': 'GOLD', 'cat': 'TREASURE', 'emoji': '🪙', 'clue': 'Precious glittering metal'},
    {'word': 'ROSE', 'cat': 'FLOWERS', 'emoji': '🌹', 'clue': 'Fragrant red romantic bloom'},
    {'word': 'FIRE', 'cat': 'ELEMENTS', 'emoji': '🔥', 'clue': 'Hot glowing dancing flames'},
    {'word': 'SNOW', 'cat': 'WINTER', 'emoji': '❄️', 'clue': 'Soft white frozen flakes'},
    {'word': 'WIND', 'cat': 'WEATHER', 'emoji': '💨', 'clue': 'Gentle blowing breeze'},
    {'word': 'SHIP', 'cat': 'OCEAN', 'emoji': '🚢', 'clue': 'Large vessel sailing oceans'},
    {'word': 'CAKE', 'cat': 'SWEETS', 'emoji': '🎂', 'clue': 'Sweet birthday celebration'},
    {'word': 'TREE', 'cat': 'NATURE', 'emoji': '🌳', 'clue': 'Tall leafy outdoor giant'},
    {'word': 'BOOK', 'cat': 'LEARNING', 'emoji': '📖', 'clue': 'Pages filled with stories'},
    {'word': 'RING', 'cat': 'JEWELRY', 'emoji': '💍', 'clue': 'Sparkling band on finger'},
    {'word': 'BELL', 'cat': 'MUSIC', 'emoji': '🔔', 'clue': 'Rings with clear chime'},
    {'word': 'KING', 'cat': 'ROYALTY', 'emoji': '👑', 'clue': 'Ruler of the royal kingdom'},
    {'word': 'LEAF', 'cat': 'NATURE', 'emoji': '🍃', 'clue': 'Green foliage on branches'},
    {'word': 'MILK', 'cat': 'DRINKS', 'emoji': '🥛', 'clue': 'Calcium rich white dairy'},
    {'word': 'RAIN', 'cat': 'WEATHER', 'emoji': '🌧️', 'clue': 'Water drops from clouds'},
    {'word': 'BOAT', 'cat': 'VEHICLES', 'emoji': '⛵', 'clue': 'Floats upon calm waters'},
    {'word': 'DOOR', 'cat': 'HOUSE', 'emoji': '🚪', 'clue': 'Entrance to home rooms'},
    {'word': 'PARK', 'cat': 'OUTDOORS', 'emoji': '🏞️', 'clue': 'Green open public space'},
    {'word': 'CORN', 'cat': 'FARM', 'emoji': '🌽', 'clue': 'Yellow sweet cob crop'},
    {'word': 'HOME', 'cat': 'FAMILY', 'emoji': '🏡', 'clue': 'Cozy place to live in'},
    {'word': 'NEST', 'cat': 'BIRDS', 'emoji': '🪺', 'clue': 'Twig shelter for eggs'},
    {'word': 'SOUP', 'cat': 'FOOD', 'emoji': '🥣', 'clue': 'Warm comforting broth'},
    {'word': 'DRUM', 'cat': 'MUSIC', 'emoji': '🥁', 'clue': 'Beats with rhythm sticks'},
    {'word': 'KITE', 'cat': 'GAMES', 'emoji': '🪁', 'clue': 'Soars in high windy sky'},
    {'word': 'COIN', 'cat': 'TREASURE', 'emoji': '🪙', 'clue': 'Shiny round currency token'},
  ];

  // ==========================================
  // TIER 3: 5-LETTER WORDS (Levels 26 - 70)
  // ==========================================
  static const List<Map<String, dynamic>> _words5 = [
    {'word': 'APPLE', 'cat': 'FRUITS', 'emoji': '🍎', 'clue': 'Crisp sweet orchard fruit'},
    {'word': 'TIGER', 'cat': 'SAFARI', 'emoji': '🐯', 'clue': 'Striped predator of jungle'},
    {'word': 'PANDA', 'cat': 'ANIMALS', 'emoji': '🐼', 'clue': 'Eats fresh green bamboo'},
    {'word': 'PIZZA', 'cat': 'FOOD', 'emoji': '🍕', 'clue': 'Crust with melted cheese'},
    {'word': 'ZEBRA', 'cat': 'SAFARI', 'emoji': '🦓', 'clue': 'Black and white striped'},
    {'word': 'HORSE', 'cat': 'FARM', 'emoji': '🐴', 'clue': 'Gallops fast with hooves'},
    {'word': 'TRAIN', 'cat': 'VEHICLES', 'emoji': '🚂', 'clue': 'Rides along steel rails'},
    {'word': 'MANGO', 'cat': 'FRUITS', 'emoji': '🥭', 'clue': 'Juicy tropical golden king'},
    {'word': 'BEACH', 'cat': 'COAST', 'emoji': '🏖️', 'clue': 'Golden sand by ocean surf'},
    {'word': 'SHARK', 'cat': 'OCEAN', 'emoji': '🦈', 'clue': 'Apex predator of the sea'},
    {'word': 'PLANE', 'cat': 'TRAVEL', 'emoji': '✈️', 'clue': 'Cruises high in clouds'},
    {'word': 'CLOUD', 'cat': 'WEATHER', 'emoji': '☁️', 'clue': 'Fluffy mass in blue sky'},
    {'word': 'OCEAN', 'cat': 'NATURE', 'emoji': '🌊', 'clue': 'Massive blue water body'},
    {'word': 'EARTH', 'cat': 'SPACE', 'emoji': '🌍', 'clue': 'Our green and blue planet'},
    {'word': 'CHAIR', 'cat': 'FURNITURE', 'emoji': '🪑', 'clue': 'Four legs built to sit on'},
    {'word': 'BREAD', 'cat': 'BAKERY', 'emoji': '🍞', 'clue': 'Fresh warm baked staple'},
    {'word': 'SMILE', 'cat': 'EMOTION', 'emoji': '😊', 'clue': 'Cheer across happy face'},
    {'word': 'SWEET', 'cat': 'TASTE', 'emoji': '🍬', 'clue': 'Sugary confectionery flavor'},
    {'word': 'RIVER', 'cat': 'NATURE', 'emoji': '🏞️', 'clue': 'Flows toward deep sea'},
    {'word': 'TOWER', 'cat': 'BUILDINGS', 'emoji': '🗼', 'clue': 'Tall skyscraper structure'},
    {'word': 'MUSIC', 'cat': 'ARTS', 'emoji': '🎵', 'clue': 'Pleasing rhythmic melody'},
    {'word': 'CANDY', 'cat': 'SNACKS', 'emoji': '🍭', 'clue': 'Delicious sugary treat'},
    {'word': 'LEMON', 'cat': 'FRUITS', 'emoji': '🍋', 'clue': 'Sour yellow citrus wedge'},
    {'word': 'STORM', 'cat': 'WEATHER', 'emoji': '⛈️', 'clue': 'Thunder and pouring rain'},
    {'word': 'MAGIC', 'cat': 'FANTASY', 'emoji': '✨', 'clue': 'Mystical sorcery wonder'},
    {'word': 'GHOST', 'cat': 'SPOOKY', 'emoji': '👻', 'clue': 'Ethereal floating spirit'},
    {'word': 'CROWN', 'cat': 'ROYALTY', 'emoji': '👑', 'clue': 'Golden jewel-encrusted headwear'},
    {'word': 'HEART', 'cat': 'LOVE', 'emoji': '❤️', 'clue': 'Symbol of care and pulse'},
    {'word': 'LIGHT', 'cat': 'PHYSICS', 'emoji': '💡', 'clue': 'Illuminates the dark room'},
    {'word': 'ROBOT', 'cat': 'TECH', 'emoji': '🤖', 'clue': 'Automated mechanical machine'},
    {'word': 'SWORD', 'cat': 'WEAPONS', 'emoji': '⚔️', 'clue': 'Sharp steel knight blade'},
    {'word': 'WATER', 'cat': 'ESSENTIAL', 'emoji': '💧', 'clue': 'Pure fluid giving life'},
    {'word': 'GRAPE', 'cat': 'FRUITS', 'emoji': '🍇', 'clue': 'Juicy purple vineyard bunch'},
    {'word': 'CAMEL', 'cat': 'DESERT', 'emoji': '🐫', 'clue': 'Humps across desert sand'},
    {'word': 'SHEEP', 'cat': 'FARM', 'emoji': '🐑', 'clue': 'Fluffy animal giving wool'},
    {'word': 'WHALE', 'cat': 'OCEAN', 'emoji': '🐋', 'clue': 'Giant friendly sea mammal'},
    {'word': 'EAGLE', 'cat': 'BIRDS', 'emoji': '🦅', 'clue': 'Majestic soaring predator'},
    {'word': 'ONION', 'cat': 'VEGGIES', 'emoji': '🧅', 'clue': 'Layers that make cooks tear'},
    {'word': 'BERRY', 'cat': 'FRUITS', 'emoji': '🍓', 'clue': 'Small tart forest fruit'},
    {'word': 'CLOCK', 'cat': 'TIME', 'emoji': '⏰', 'clue': 'Keeps accurate track of hours'},
  ];

  // ==========================================
  // TIER 4: 6-LETTER WORDS (Levels 71 - 140)
  // ==========================================
  static const List<Map<String, dynamic>> _words6 = [
    {'word': 'MONKEY', 'cat': 'WILDLIFE', 'emoji': '🐒', 'clue': 'Swings between jungle trees'},
    {'word': 'BANANA', 'cat': 'FRUITS', 'emoji': '🍌', 'clue': 'Yellow fruit rich in potassium'},
    {'word': 'ROCKET', 'cat': 'SPACE', 'emoji': '🚀', 'clue': 'Launches high into orbit'},
    {'word': 'GUITAR', 'cat': 'MUSIC', 'emoji': '🎸', 'clue': 'Strumming acoustic melodies'},
    {'word': 'TURTLE', 'cat': 'REPTILES', 'emoji': '🐢', 'clue': 'Carries hardened shell house'},
    {'word': 'ORANGE', 'cat': 'FRUITS', 'emoji': '🍊', 'clue': 'Citrus peel fruit full of C'},
    {'word': 'CASTLE', 'cat': 'HERITAGE', 'emoji': '🏰', 'clue': 'Medieval stone stronghold'},
    {'word': 'CHERRY', 'cat': 'FRUITS', 'emoji': '🍒', 'clue': 'Twin sweet red stem fruit'},
    {'word': 'PARROT', 'cat': 'BIRDS', 'emoji': '🦜', 'clue': 'Colorful talking tropical bird'},
    {'word': 'WIZARD', 'cat': 'MAGIC', 'emoji': '🧙', 'clue': 'Enchanter with mystical wand'},
    {'word': 'ISLAND', 'cat': 'GEOGRAPHY', 'emoji': '🏝️', 'clue': 'Land encompassed by sea'},
    {'word': 'DRAGON', 'cat': 'FANTASY', 'emoji': '🐉', 'clue': 'Fire-breathing winged legend'},
    {'word': 'GALAXY', 'cat': 'COSMOS', 'emoji': '🌌', 'clue': 'Vast swirling spiral of stars'},
    {'word': 'FLOWER', 'cat': 'GARDEN', 'emoji': '🌸', 'clue': 'Sweet fragrant colorful petal'},
    {'word': 'RABBIT', 'cat': 'ANIMALS', 'emoji': '🐰', 'clue': 'Long ears hopping on lawn'},
    {'word': 'DOLPHIN', 'cat': 'OCEAN', 'emoji': '🐬', 'clue': 'Playful leaping sea friend'},
    {'word': 'PLANET', 'cat': 'SPACE', 'emoji': '🪐', 'clue': 'Celestial body orbiting sun'},
    {'word': 'JUNGLE', 'cat': 'NATURE', 'emoji': '🌴', 'clue': 'Dense tropical rain forest'},
    {'word': 'BRIDGE', 'cat': 'STRUCTURES', 'emoji': '🌉', 'clue': 'Spans across deep canyon'},
    {'word': 'CAMERA', 'cat': 'TECH', 'emoji': '📷', 'clue': 'Captures precious memories'},
    {'word': 'TEMPLE', 'cat': 'ANCIENT', 'emoji': '🏛️', 'clue': 'Sacred ancient holy palace'},
    {'word': 'SILVER', 'cat': 'TREASURE', 'emoji': '🥈', 'clue': 'Gleaming valuable grey metal'},
    {'word': 'SUNSET', 'cat': 'TWILIGHT', 'emoji': '🌇', 'clue': 'Evening sky of red & gold'},
    {'word': 'FOREST', 'cat': 'NATURE', 'emoji': '🌲', 'clue': 'Woodland full of tall pines'},
    {'word': 'PIRATE', 'cat': 'ADVENTURE', 'emoji': '🏴‍☠️', 'clue': 'Searches sea for lost chests'},
    {'word': 'CANDLE', 'cat': 'LIGHT', 'emoji': '🕯️', 'clue': 'Wax stick with burning wick'},
    {'word': 'KNIGHT', 'cat': 'MEDIEVAL', 'emoji': '🛡️', 'clue': 'Warrior wearing iron armor'},
    {'word': 'BREEZE', 'cat': 'WEATHER', 'emoji': '🍃', 'clue': 'Refreshing cool gentle air'},
    {'word': 'MAGNET', 'cat': 'SCIENCE', 'emoji': '🧲', 'clue': 'Attracts iron and steel'},
    {'word': 'PENCIL', 'cat': 'STATIONERY', 'emoji': '✏️', 'clue': 'Graphite tool for writing'},
    {'word': 'WINDOW', 'cat': 'HOUSE', 'emoji': '🪟', 'clue': 'Glass panel showing outdoors'},
    {'word': 'SPIDER', 'cat': 'INSECTS', 'emoji': '🕷️', 'clue': 'Eight-legged web spinner'},
    {'word': 'BASKET', 'cat': 'PICNIC', 'emoji': '🧺', 'clue': 'Woven container for goods'},
    {'word': 'CIRCUS', 'cat': 'SHOWS', 'emoji': '🎪', 'clue': 'Acrobats and tent wonders'},
    {'word': 'FALCON', 'cat': 'BIRDS', 'emoji': '🦅', 'clue': 'Fastest diving hunting bird'},
  ];

  // ==========================================
  // TIER 5: 7-LETTER WORDS (Levels 141 - 240)
  // ==========================================
  static const List<Map<String, dynamic>> _words7 = [
    {'word': 'PENGUIN', 'cat': 'POLAR', 'emoji': '🐧', 'clue': 'Waddles over freezing ice'},
    {'word': 'GIRAFFE', 'cat': 'SAFARI', 'emoji': '🦒', 'clue': 'Towering tall long neck'},
    {'word': 'POPCORN', 'cat': 'SNACKS', 'emoji': '🍿', 'clue': 'Movie snack roasted hot'},
    {'word': 'RAINBOW', 'cat': 'OPTICS', 'emoji': '🌈', 'clue': 'Seven colors after shower'},
    {'word': 'OCTOPUS', 'cat': 'OCEAN', 'emoji': '🐙', 'clue': 'Eight arms in coral reef'},
    {'word': 'DIAMOND', 'cat': 'GEMS', 'emoji': '💎', 'clue': 'Sparkling brilliant stone'},
    {'word': 'CAMPING', 'cat': 'OUTDOORS', 'emoji': '⛺', 'clue': 'Tent adventures under stars'},
    {'word': 'JUPITER', 'cat': 'PLANETS', 'emoji': '🪐', 'clue': 'Colossal stormy giant planet'},
    {'word': 'BALLOON', 'cat': 'PARTY', 'emoji': '🎈', 'clue': 'Inflated fun floating sphere'},
    {'word': 'FEATHER', 'cat': 'BIRDS', 'emoji': '🪶', 'clue': 'Light plumed wing covering'},
    {'word': 'CRYSTAL', 'cat': 'MINERALS', 'emoji': '🔮', 'clue': 'Geometric clear gemstone'},
    {'word': 'VOLCANO', 'cat': 'GEOLOGY', 'emoji': '🌋', 'clue': 'Mountain erupting hot lava'},
    {'word': 'LANTERN', 'cat': 'LIGHT', 'emoji': '🏮', 'clue': 'Portable outdoor lamp cage'},
    {'word': 'BLANKET', 'cat': 'COMFORT', 'emoji': '🛋️', 'clue': 'Keeps you warm in bedtime'},
    {'word': 'WHISPER', 'cat': 'SOUNDS', 'emoji': '🤫', 'clue': 'Quiet confidential speaking'},
    {'word': 'THUNDER', 'cat': 'STORMS', 'emoji': '⚡', 'clue': 'Loud boom during rainstorms'},
    {'word': 'MONSTER', 'cat': 'CREATURES', 'emoji': '👾', 'clue': 'Giant imaginary fantasy beast'},
    {'word': 'HAMSTER', 'cat': 'PETS', 'emoji': '🐹', 'clue': 'Tiny rodent in running wheel'},
    {'word': 'CHEETAH', 'cat': 'SPEED', 'emoji': '🐆', 'clue': 'Fastest running land mammal'},
    {'word': 'JOURNEY', 'cat': 'ADVENTURE', 'emoji': '🧭', 'clue': 'Expedition across new lands'},
    {'word': 'MYSTERY', 'cat': 'RIDDLES', 'emoji': '🔍', 'clue': 'Secret waiting to be solved'},
    {'word': 'PYRAMID', 'cat': 'ANCIENT', 'emoji': '🏛️', 'clue': 'Triangle stone monument tomb'},
    {'word': 'CAPTAIN', 'cat': 'NAUTICAL', 'emoji': '🧑‍✈️', 'clue': 'Commander of ships or crew'},
    {'word': 'BLOSSOM', 'cat': 'BOTANY', 'emoji': '🌸', 'clue': 'Spring petals bursting open'},
    {'word': 'CHIMNEY', 'cat': 'ROOF', 'emoji': '🏠', 'clue': 'Channel for fireplace smoke'},
    {'word': 'PEACOCK', 'cat': 'BIRDS', 'emoji': '🦚', 'clue': 'Magnificent fan of plumage'},
    {'word': 'SEAHORSE', 'cat': 'OCEAN', 'emoji': '🌊', 'clue': 'Tiny curled aquatic swimmer'},
    {'word': 'COCONUT', 'cat': 'PALMS', 'emoji': '🥥', 'clue': 'Hard brown tropical nut juice'},
    {'word': 'GLACIER', 'cat': 'ARCTIC', 'emoji': '🧊', 'clue': 'Massive flowing sheet of ice'},
    {'word': 'UNICORN', 'cat': 'MYTHICAL', 'emoji': '🦄', 'clue': 'Magical horse with a horn'},
  ];

  // ==========================================
  // TIER 6: 8-LETTER WORDS (Levels 241+)
  // ==========================================
  static const List<Map<String, dynamic>> _words8 = [
    {'word': 'ELEPHANT', 'cat': 'SAFARI', 'emoji': '🐘', 'clue': 'Gentle giant with trunk & tusks'},
    {'word': 'DINOSAUR', 'cat': 'PREHISTORIC', 'emoji': '🦖', 'clue': 'Ancient extinct reptiles'},
    {'word': 'FLAMINGO', 'cat': 'WETLANDS', 'emoji': '🦩', 'clue': 'Bright pink one-legged bird'},
    {'word': 'AIRPLANE', 'cat': 'AVIATION', 'emoji': '✈️', 'clue': 'Passenger jet cruising sky'},
    {'word': 'MOUNTAIN', 'cat': 'SUMMITS', 'emoji': '🏔️', 'clue': 'Towering snowy alpine peak'},
    {'word': 'SANDWICH', 'cat': 'LUNCH', 'emoji': '🥪', 'clue': 'Fillings between bread slices'},
    {'word': 'CHAMPION', 'cat': 'VICTORY', 'emoji': '🏆', 'clue': 'Winner of the tournament'},
    {'word': 'TREASURE', 'cat': 'BOUNTY', 'emoji': '💎', 'clue': 'Hidden chest of riches'},
    {'word': 'UNIVERSE', 'cat': 'INFINITY', 'emoji': '🌌', 'clue': 'All of space, time, & matter'},
    {'word': 'SQUIRREL', 'cat': 'FOREST', 'emoji': '🐿️', 'clue': 'Bushy tail gathering acorns'},
    {'word': 'KANGAROO', 'cat': 'OUTBACK', 'emoji': '🦘', 'clue': 'Hops forward carrying joey'},
    {'word': 'FIREWORK', 'cat': 'FESTIVAL', 'emoji': '🎆', 'clue': 'Sparkling explosions in sky'},
    {'word': 'PRINCESS', 'cat': 'ROYALTY', 'emoji': '👸', 'clue': 'Daughter of the king & queen'},
    {'word': 'BACKPACK', 'cat': 'SCHOOL', 'emoji': '🎒', 'clue': 'Carries books and stationery'},
    {'word': 'BLUEBIRD', 'cat': 'SONGS', 'emoji': '🐦', 'clue': 'Blue feathers singing softly'},
    {'word': 'SUNSHINE', 'cat': 'DAYLIGHT', 'emoji': '☀️', 'clue': 'Warm gentle morning rays'},
    {'word': 'CUPCAKE', 'cat': 'DESSERT', 'emoji': '🧁', 'clue': 'Frosted miniature sweet cake'},
    {'word': 'FOOTBALL', 'cat': 'SPORTS', 'emoji': '⚽', 'clue': 'Game kicked on grass pitches'},
    {'word': 'WATERFALL', 'cat': 'CASCADES', 'emoji': '🌊', 'clue': 'Torrents cascading off cliff'},
    {'word': 'STARFISH', 'cat': 'REEFS', 'emoji': '⭐', 'clue': 'Five-armed creature on sand'},
    {'word': 'SEASHELL', 'cat': 'SHORELINE', 'emoji': '🐚', 'clue': 'Exoskeleton found on beach'},
    {'word': 'PLATYPUS', 'cat': 'ODDITIES', 'emoji': '🦆', 'clue': 'Duck-billed Australian mammal'},
    {'word': 'MUSHROOM', 'cat': 'FUNGI', 'emoji': '🍄', 'clue': 'Fungus cap growing in shade'},
    {'word': 'LIGHTNING', 'cat': 'STORMS', 'emoji': '⚡', 'clue': 'Fierce electrical sky bolt'},
    {'word': 'ADVENTURE', 'cat': 'QUESTS', 'emoji': '🗺️', 'clue': 'Thrilling voyage of discovery'},
    {'word': 'BUTTERFLY', 'cat': 'METAMORPH', 'emoji': '🦋', 'clue': 'Caterpillar transformed to wings'},
    {'word': 'SATELLITE', 'cat': 'TECH', 'emoji': '🛰️', 'clue': 'Transmits signals from orbit'},
    {'word': 'SUBMARINE', 'cat': 'NAVAL', 'emoji': '🚢', 'clue': 'Cruises deep below surface'},
    {'word': 'TELESCOPE', 'cat': 'ASTRONOMY', 'emoji': '🔭', 'clue': 'Magnifies distant galaxies'},
    {'word': 'CHOCOLATE', 'cat': 'CONFECTION', 'emoji': '🍫', 'clue': 'Delicious cocoa bean treat'},
  ];

  static const List<String> _distractorLetters = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
    'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'
  ];

  /// Core Progressive Difficulty Curve mapping Level -> Target Word Length
  static int getWordLengthForLevel(int level) {
    if (level <= 5) return 3; // Warmups
    if (level <= 25) return 4; // Beginner
    if (level <= 70) return 5; // Casual
    if (level <= 140) return 6; // Medium
    if (level <= 240) return 7; // Hard
    if (level <= 380) return 8; // Expert

    // Beyond level 380: Infinite periodic difficulty waves
    // Every 40 levels forms a wave with escalating challenge:
    // Wave 1-10: 6 letters
    // Wave 11-25: 7 letters
    // Wave 26-40: 8 letters
    final waveOffset = (level - 381) % 40;
    if (waveOffset < 10) return 6;
    if (waveOffset < 25) return 7;
    return 8;
  }

  /// Determines tile pool size:
  /// Level 1-15: 10 tiles (5x2 grid)
  /// Level 16+: 12 tiles (6x2 grid) for rich distractor challenge
  static int getPoolSizeForLevel(int level, int wordLength) {
    if (wordLength <= 3) return 10;
    if (wordLength == 4 && level <= 15) return 10;
    return 12;
  }

  /// Helper returning the word list corresponding to the desired length
  static List<Map<String, dynamic>> _getWordListForLength(int len) {
    switch (len) {
      case 3:
        return _words3;
      case 4:
        return _words4;
      case 5:
        return _words5;
      case 6:
        return _words6;
      case 7:
        return _words7;
      case 8:
      default:
        return _words8;
    }
  }

  /// Master level generator supporting infinite levels (Level 1 to 10,000+)
  /// with deterministic progressive difficulty.
  static BalloonPuzzle getPuzzleForLevel(int level) {
    final wordLength = getWordLengthForLevel(level);
    final wordList = _getWordListForLength(wordLength);

    // Pick deterministically without consecutive repeats using coprime stride 7
    final itemIndex = (level * 7 + 13) % wordList.length;
    final item = wordList[itemIndex];

    final word = (item['word'] as String).toUpperCase();
    final cat = item['cat'] as String;
    final emoji = item['emoji'] as String;
    final clue = item['clue'] as String;

    final poolSize = getPoolSizeForLevel(level, word.length);
    final pool = _generateSmartLetterPool(
      word: word,
      poolSize: poolSize,
      level: level,
    );

    return BalloonPuzzle(
      level: level,
      word: word,
      category: cat,
      emoji: emoji,
      clue: clue,
      poolSize: poolSize,
      letterPool: pool,
    );
  }

  /// Generates letter pool with progressive intelligence:
  /// - Low levels: simple distractors that don't confuse
  /// - High levels: smart vowel decoys and common tricky consonants
  static List<String> _generateSmartLetterPool({
    required String word,
    required int poolSize,
    required int level,
  }) {
    // Deterministic seed based on level & word
    final rand = math.Random(level * 7919 + word.hashCode);
    final List<String> pool = [];

    // 1. Add all unique letters of target word (and account for duplicates)
    final wordLetters = word.split('');
    pool.addAll(wordLetters);

    final usedChars = Set<String>.from(wordLetters);
    final vowels = ['A', 'E', 'I', 'O', 'U'];
    final trickyConsonants = ['S', 'R', 'T', 'N', 'L', 'D', 'M', 'C', 'P', 'H', 'B', 'K', 'Y'];

    // 2. In higher levels (level >= 30), inject at least 1-2 decoy vowels
    if (level >= 30 && pool.length < poolSize) {
      final unusedVowels = vowels.where((v) => !usedChars.contains(v)).toList();
      if (unusedVowels.isNotEmpty) {
        final decoyVowel = unusedVowels[rand.nextInt(unusedVowels.length)];
        pool.add(decoyVowel);
        usedChars.add(decoyVowel);
      }
    }

    // 3. In higher levels (level >= 60), inject a decoy tricky consonant
    if (level >= 60 && pool.length < poolSize) {
      final unusedTricky = trickyConsonants.where((c) => !usedChars.contains(c)).toList();
      if (unusedTricky.isNotEmpty) {
        final decoyConsonant = unusedTricky[rand.nextInt(unusedTricky.length)];
        pool.add(decoyConsonant);
        usedChars.add(decoyConsonant);
      }
    }

    // 4. Fill remaining slots with common balanced letters
    final lettersNeeded = poolSize - pool.length;
    for (int i = 0; i < lettersNeeded; i++) {
      String candidate;
      int attempts = 0;
      do {
        if (level < 20) {
          // Low level: pick from standard distribution
          candidate = _distractorLetters[rand.nextInt(_distractorLetters.length)];
        } else {
          // Higher level: pick from high-frequency consonants
          candidate = attempts < 8
              ? trickyConsonants[rand.nextInt(trickyConsonants.length)]
              : _distractorLetters[rand.nextInt(_distractorLetters.length)];
        }
        attempts++;
      } while (usedChars.contains(candidate) && attempts < 25);

      pool.add(candidate);
      usedChars.add(candidate);
    }

    // 5. Deterministically shuffle so order is completely mixed
    pool.shuffle(rand);
    return pool;
  }
}
