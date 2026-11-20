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
  // TIER 1: 3-LETTER WORDS (Levels 1 - 5) - 50 Words
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
    {'word': 'PEN', 'cat': 'STATIONERY', 'emoji': '🖊️', 'clue': 'Tool for writing in ink'},
    {'word': 'BED', 'cat': 'FURNITURE', 'emoji': '🛏️', 'clue': 'Cozy place to sleep at night'},
    {'word': 'EGG', 'cat': 'FOOD', 'emoji': '🥚', 'clue': 'Laid by hens for breakfast'},
    {'word': 'JAM', 'cat': 'FOOD', 'emoji': '🍓', 'clue': 'Sweet fruit spread on toast'},
    {'word': 'BOY', 'cat': 'PEOPLE', 'emoji': '👦', 'clue': 'Young cheerful male child'},
    {'word': 'EYE', 'cat': 'BODY', 'emoji': '👁️', 'clue': 'Used for seeing the world'},
    {'word': 'GEM', 'cat': 'TREASURE', 'emoji': '💎', 'clue': 'Sparkling precious jewel'},
    {'word': 'LIP', 'cat': 'BODY', 'emoji': '👄', 'clue': 'Part of the smiling mouth'},
    {'word': 'PAN', 'cat': 'KITCHEN', 'emoji': '🍳', 'clue': 'Cookware for frying food'},
    {'word': 'POT', 'cat': 'KITCHEN', 'emoji': '🍲', 'clue': 'Deep vessel for hot soup'},
    {'word': 'BOW', 'cat': 'ACCESSORY', 'emoji': '🎀', 'clue': 'Decorative ribbon knot'},
    {'word': 'FAN', 'cat': 'OBJECTS', 'emoji': '🪭', 'clue': 'Creates a refreshing breeze'},
    {'word': 'LOG', 'cat': 'FOREST', 'emoji': '🪵', 'clue': 'Fallen tree trunk wood'},
    {'word': 'PIN', 'cat': 'OBJECTS', 'emoji': '🧷', 'clue': 'Sharp metal fastener'},
    {'word': 'JAR', 'cat': 'KITCHEN', 'emoji': '🫙', 'clue': 'Glass container for jams'},
    {'word': 'NET', 'cat': 'TOOLS', 'emoji': '🕸️', 'clue': 'Woven mesh to catch fish'},
    {'word': 'BUG', 'cat': 'NATURE', 'emoji': '🐛', 'clue': 'Tiny crawling insect'},
    {'word': 'TOP', 'cat': 'TOYS', 'emoji': '🪙', 'clue': 'Spins rapidly on its tip'},
    {'word': 'FLY', 'cat': 'INSECTS', 'emoji': '🪰', 'clue': 'Buzzing winged creature'},
    {'word': 'HEN', 'cat': 'FARM', 'emoji': '🐔', 'clue': 'Female chicken on the farm'},
    {'word': 'ARM', 'cat': 'BODY', 'emoji': '💪', 'clue': 'Limb used to lift things'},
    {'word': 'LEG', 'cat': 'BODY', 'emoji': '🦵', 'clue': 'Limb used for walking'},
    {'word': 'EAR', 'cat': 'BODY', 'emoji': '👂', 'clue': 'Sense organ for hearing'},
    {'word': 'DAY', 'cat': 'TIME', 'emoji': '☀️', 'clue': 'Period of bright daylight'},
    {'word': 'SKY', 'cat': 'NATURE', 'emoji': '🌌', 'clue': 'Blue expanse above earth'},
  ];

  // ==========================================
  // TIER 2: 4-LETTER WORDS (Levels 6 - 25) - 80 Words
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
    {'word': 'BLUE', 'cat': 'COLORS', 'emoji': '💙', 'clue': 'Color of clear skies & sea'},
    {'word': 'PINK', 'cat': 'COLORS', 'emoji': '🌸', 'clue': 'Soft pastel rosy shade'},
    {'word': 'RUBY', 'cat': 'GEMS', 'emoji': '💎', 'clue': 'Deep crimson red gemstone'},
    {'word': 'PEAR', 'cat': 'FRUITS', 'emoji': '🍐', 'clue': 'Juicy bell-shaped orchard fruit'},
    {'word': 'PLUM', 'cat': 'FRUITS', 'emoji': '🫐', 'clue': 'Sweet purple stone fruit'},
    {'word': 'KIWI', 'cat': 'FRUITS', 'emoji': '🥝', 'clue': 'Brown fuzzy fruit green inside'},
    {'word': 'CRAB', 'cat': 'OCEAN', 'emoji': '🦀', 'clue': 'Side-walking beach crustacean'},
    {'word': 'SEAL', 'cat': 'ARCTIC', 'emoji': '🦭', 'clue': 'Whiskered playful sea mammal'},
    {'word': 'GOAT', 'cat': 'FARM', 'emoji': '🐐', 'clue': 'Horned animal that climbs'},
    {'word': 'LAMB', 'cat': 'FARM', 'emoji': '🐑', 'clue': 'Gentle young woolly sheep'},
    {'word': 'PONY', 'cat': 'ANIMALS', 'emoji': '🐴', 'clue': 'Small adorable gentle horse'},
    {'word': 'SWAN', 'cat': 'BIRDS', 'emoji': '🦢', 'clue': 'Graceful white lake bird'},
    {'word': 'MOTH', 'cat': 'INSECTS', 'emoji': '🦋', 'clue': 'Nocturnal flutterer near light'},
    {'word': 'WASP', 'cat': 'INSECTS', 'emoji': '🐝', 'clue': 'Stinging yellow striped flyer'},
    {'word': 'WAVE', 'cat': 'OCEAN', 'emoji': '🌊', 'clue': 'Curling surge of seawater'},
    {'word': 'SAND', 'cat': 'BEACH', 'emoji': '🏖️', 'clue': 'Fine grains along sunny shores'},
    {'word': 'ROCK', 'cat': 'NATURE', 'emoji': '🪨', 'clue': 'Solid natural stone boulder'},
    {'word': 'DUST', 'cat': 'NATURE', 'emoji': '💨', 'clue': 'Tiny dry earth particles'},
    {'word': 'SOIL', 'cat': 'GARDEN', 'emoji': '🌱', 'clue': 'Rich earth where seeds grow'},
    {'word': 'SEED', 'cat': 'PLANTS', 'emoji': '🌰', 'clue': 'Sprouts into green plants'},
    {'word': 'BARK', 'cat': 'TREES', 'emoji': '🪵', 'clue': 'Rough outer skin of trees'},
    {'word': 'WOOD', 'cat': 'FOREST', 'emoji': '🪵', 'clue': 'Timber from forest trees'},
    {'word': 'ROOT', 'cat': 'PLANTS', 'emoji': '🌿', 'clue': 'Anchors the plant in earth'},
    {'word': 'HERB', 'cat': 'GARDEN', 'emoji': '🌿', 'clue': 'Fragrant plant for cooking'},
    {'word': 'MINT', 'cat': 'GARDEN', 'emoji': '🌱', 'clue': 'Cool refreshing fragrant leaf'},
    {'word': 'FERN', 'cat': 'PLANTS', 'emoji': '🌿', 'clue': 'Feathery green shade plant'},
    {'word': 'ROPE', 'cat': 'TOOLS', 'emoji': '🪢', 'clue': 'Strong twisted cord for tying'},
    {'word': 'LAMP', 'cat': 'LIGHT', 'emoji': '🪔', 'clue': 'Electric light on side table'},
    {'word': 'DESK', 'cat': 'STUDY', 'emoji': '🪵', 'clue': 'Wooden table for study work'},
    {'word': 'BOWL', 'cat': 'KITCHEN', 'emoji': '🥣', 'clue': 'Curved dish for cereal & soup'},
    {'word': 'FORK', 'cat': 'DINING', 'emoji': '🍴', 'clue': 'Pronged utensil for eating'},
    {'word': 'COOK', 'cat': 'KITCHEN', 'emoji': '👨‍🍳', 'clue': 'Prepares delicious warm meals'},
    {'word': 'BAKE', 'cat': 'KITCHEN', 'emoji': '🥖', 'clue': 'Cooks bread inside hot oven'},
    {'word': 'BALL', 'cat': 'SPORTS', 'emoji': '⚽', 'clue': 'Round sphere for fun games'},
    {'word': 'GAME', 'cat': 'FUN', 'emoji': '🎮', 'clue': 'Playful recreational activity'},
    {'word': 'SONG', 'cat': 'MUSIC', 'emoji': '🎵', 'clue': 'Melody sung with sweet voice'},
    {'word': 'TUNE', 'cat': 'MUSIC', 'emoji': '🎶', 'clue': 'Catchy musical pitch notes'},
    {'word': 'ECHO', 'cat': 'SOUNDS', 'emoji': '📢', 'clue': 'Sound bouncing off canyon walls'},
    {'word': 'ROAD', 'cat': 'TRAVEL', 'emoji': '🛣️', 'clue': 'Paved path for car journeys'},
    {'word': 'PATH', 'cat': 'OUTDOORS', 'emoji': '🛤️', 'clue': 'Walking trail through nature'},
    {'word': 'CITY', 'cat': 'PLACES', 'emoji': '🏙️', 'clue': 'Bustling metropolis skyline'},
    {'word': 'TOWN', 'cat': 'PLACES', 'emoji': '🏘️', 'clue': 'Cozy community of houses'},
    {'word': 'BARN', 'cat': 'FARM', 'emoji': '🚜', 'clue': 'Red farm storage for hay'},
    {'word': 'SHED', 'cat': 'GARDEN', 'emoji': '🛖', 'clue': 'Backyard hut for garden tools'},
    {'word': 'FORT', 'cat': 'CASTLES', 'emoji': '🏰', 'clue': 'Stronghold built for defense'},
  ];

  // ==========================================
  // TIER 3: 5-LETTER WORDS (Levels 26 - 70) - 80 Words
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
    {'word': 'KOALA', 'cat': 'ANIMALS', 'emoji': '🐨', 'clue': 'Sleepy eucalyptus tree climber'},
    {'word': 'OTTER', 'cat': 'WILDLIFE', 'emoji': '🦦', 'clue': 'Playful river swimmer with fur'},
    {'word': 'MOOSE', 'cat': 'WILDLIFE', 'emoji': '🫎', 'clue': 'Large antlered forest giant'},
    {'word': 'VIPER', 'cat': 'REPTILES', 'emoji': '🐍', 'clue': 'Slithering venomous snake'},
    {'word': 'ROBIN', 'cat': 'BIRDS', 'emoji': '🐦', 'clue': 'Red-breasted singing bird'},
    {'word': 'HERON', 'cat': 'BIRDS', 'emoji': '🪿', 'clue': 'Long-legged wading fisherman'},
    {'word': 'TULIP', 'cat': 'FLOWERS', 'emoji': '🌷', 'clue': 'Bright cup-shaped spring bloom'},
    {'word': 'DAISY', 'cat': 'FLOWERS', 'emoji': '🌼', 'clue': 'White petals with golden center'},
    {'word': 'LOTUS', 'cat': 'FLOWERS', 'emoji': '🪷', 'clue': 'Sacred water lily on ponds'},
    {'word': 'MAPLE', 'cat': 'TREES', 'emoji': '🍁', 'clue': 'Leaf that turns fiery red'},
    {'word': 'CEDAR', 'cat': 'TREES', 'emoji': '🌲', 'clue': 'Aromatic evergreen timber'},
    {'word': 'MELON', 'cat': 'FRUITS', 'emoji': '🍈', 'clue': 'Juicy sweet ribbed green fruit'},
    {'word': 'PEACH', 'cat': 'FRUITS', 'emoji': '🍑', 'clue': 'Velvety fuzzy sweet orchard fruit'},
    {'word': 'GUAVA', 'cat': 'FRUITS', 'emoji': '🍐', 'clue': 'Tropical pink centered treat'},
    {'word': 'CHILI', 'cat': 'SPICES', 'emoji': '🌶️', 'clue': 'Hot spicy fiery red pepper'},
    {'word': 'SALAD', 'cat': 'FOOD', 'emoji': '🥗', 'clue': 'Tossed fresh healthy greens'},
    {'word': 'TOAST', 'cat': 'FOOD', 'emoji': '🍞', 'clue': 'Crisp browned warm bread'},
    {'word': 'HONEY', 'cat': 'SWEETS', 'emoji': '🍯', 'clue': 'Golden syrup made by bees'},
    {'word': 'SUGAR', 'cat': 'SWEETS', 'emoji': '🧂', 'clue': 'Sweet white crystal sweetener'},
    {'word': 'FLUTE', 'cat': 'MUSIC', 'emoji': '🪈', 'clue': 'Wind instrument with airy tone'},
    {'word': 'PIANO', 'cat': 'MUSIC', 'emoji': '🎹', 'clue': 'Keyboard with black & white keys'},
    {'word': 'ORGAN', 'cat': 'MUSIC', 'emoji': '🎼', 'clue': 'Keyboard with echoing pipes'},
    {'word': 'RADIO', 'cat': 'TECH', 'emoji': '📻', 'clue': 'Broadcasts songs across airwaves'},
    {'word': 'SPACE', 'cat': 'COSMOS', 'emoji': '🌌', 'clue': 'Infinite expanse beyond clouds'},
    {'word': 'COMET', 'cat': 'COSMOS', 'emoji': '☄️', 'clue': 'Icy celestial body with tail'},
    {'word': 'SOLAR', 'cat': 'ENERGY', 'emoji': '☀️', 'clue': 'Energy powered by the sun'},
    {'word': 'SHINE', 'cat': 'LIGHT', 'emoji': '✨', 'clue': 'Radiate bright sparkling light'},
    {'word': 'FLAME', 'cat': 'FIRE', 'emoji': '🔥', 'clue': 'Licking tongue of hot blaze'},
    {'word': 'FROST', 'cat': 'WINTER', 'emoji': '❄️', 'clue': 'Delicate ice crust on leaves'},
    {'word': 'CLIFF', 'cat': 'NATURE', 'emoji': '🧗', 'clue': 'Steep vertical rocky precipice'},
    {'word': 'OASIS', 'cat': 'DESERT', 'emoji': '🌴', 'clue': 'Fertile spring amid sandy dunes'},
    {'word': 'TRAIL', 'cat': 'HIKING', 'emoji': '🥾', 'clue': 'Path winding up mountain slope'},
    {'word': 'CABIN', 'cat': 'HOUSES', 'emoji': '🛖', 'clue': 'Rustic wooden lodge in woods'},
    {'word': 'HOTEL', 'cat': 'TRAVEL', 'emoji': '🏨', 'clue': 'Lodging for traveling guests'},
    {'word': 'WATCH', 'cat': 'TIME', 'emoji': '⌚', 'clue': 'Timepiece worn around wrist'},
    {'word': 'BADGE', 'cat': 'AWARDS', 'emoji': '📛', 'clue': 'Emblem pinned for achievement'},
    {'word': 'MEDAL', 'cat': 'AWARDS', 'emoji': '🏅', 'clue': 'Ribbon award for athletic champions'},
    {'word': 'SCARF', 'cat': 'CLOTHES', 'emoji': '🧣', 'clue': 'Warm knit wrap around neck'},
    {'word': 'GLOVE', 'cat': 'CLOTHES', 'emoji': '🧤', 'clue': 'Protective cover for cold hands'},
    {'word': 'SHIRT', 'cat': 'CLOTHES', 'emoji': '👕', 'clue': 'Upper body everyday clothing'},
  ];

  // ==========================================
  // TIER 4: 6-LETTER WORDS (Levels 71 - 140) - 80 Words
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
    {'word': 'BADGER', 'cat': 'WILDLIFE', 'emoji': '🦡', 'clue': 'Burrowing animal with striped head'},
    {'word': 'BEAVER', 'cat': 'WILDLIFE', 'emoji': '🦫', 'clue': 'Builds wooden dams across creeks'},
    {'word': 'JAGUAR', 'cat': 'WILDLIFE', 'emoji': '🐆', 'clue': 'Spotted solitary jungle hunter'},
    {'word': 'WALRUS', 'cat': 'ARCTIC', 'emoji': '🦭', 'clue': 'Tusked mammal on polar ice'},
    {'word': 'TOUCAN', 'cat': 'BIRDS', 'emoji': '🦜', 'clue': 'Enormous colorful banana bill'},
    {'word': 'CANARY', 'cat': 'BIRDS', 'emoji': '🐤', 'clue': 'Bright yellow melody singer'},
    {'word': 'PIGEON', 'cat': 'BIRDS', 'emoji': '🐦', 'clue': 'Urban bird cooing on rooftops'},
    {'word': 'BAMBOO', 'cat': 'PLANTS', 'emoji': '🎋', 'clue': 'Fastest growing hollow green cane'},
    {'word': 'CACTUS', 'cat': 'DESERT', 'emoji': '🌵', 'clue': 'Spiny succulent in arid sands'},
    {'word': 'CLOVER', 'cat': 'NATURE', 'emoji': '☘️', 'clue': 'Lucky four leaf green foliage'},
    {'word': 'PAPAYA', 'cat': 'FRUITS', 'emoji': '🍈', 'clue': 'Orange tropical sweet flesh'},
    {'word': 'TOMATO', 'cat': 'GARDEN', 'emoji': '🍅', 'clue': 'Plump red vine-grown garden fruit'},
    {'word': 'CARROT', 'cat': 'VEGGIES', 'emoji': '🥕', 'clue': 'Crunchy orange root beloved by hares'},
    {'word': 'PEPPER', 'cat': 'VEGGIES', 'emoji': '🫑', 'clue': 'Bell shaped crisp crunchy veggie'},
    {'word': 'COOKIE', 'cat': 'BAKERY', 'emoji': '🍪', 'clue': 'Baked round biscuit with choc chips'},
    {'word': 'WAFFLE', 'cat': 'BREAKFAST', 'emoji': '🧇', 'clue': 'Grid-patterned crisp breakfast cake'},
    {'word': 'BUTTER', 'cat': 'DAIRY', 'emoji': '🧈', 'clue': 'Creamy spread churned from milk'},
    {'word': 'CHEESE', 'cat': 'DAIRY', 'emoji': '🧀', 'clue': 'Cultured dairy wedge with holes'},
    {'word': 'MUFFIN', 'cat': 'BAKERY', 'emoji': '🧁', 'clue': 'Cup-shaped quick-baked breakfast treat'},
    {'word': 'VIOLIN', 'cat': 'MUSIC', 'emoji': '🎻', 'clue': 'Wooden string instrument with bow'},
    {'word': 'HARBOR', 'cat': 'COAST', 'emoji': '⚓', 'clue': 'Sheltered port where ships dock'},
    {'word': 'PALACE', 'cat': 'ROYALTY', 'emoji': '🏰', 'clue': 'Magnificent royal stately estate'},
    {'word': 'TUNNEL', 'cat': 'ROADS', 'emoji': '🚇', 'clue': 'Underground passage through hills'},
    {'word': 'STATUE', 'cat': 'ART', 'emoji': '🗽', 'clue': 'Sculpted figure of historic hero'},
    {'word': 'SHADOW', 'cat': 'LIGHT', 'emoji': '👤', 'clue': 'Dark silhouette cast by sunlight'},
    {'word': 'MIRROR', 'cat': 'OBJECTS', 'emoji': '🪞', 'clue': 'Reflective glass showing your face'},
    {'word': 'BOTTLE', 'cat': 'OBJECTS', 'emoji': '🍾', 'clue': 'Glass container holding beverages'},
    {'word': 'KETTLE', 'cat': 'KITCHEN', 'emoji': '🫖', 'clue': 'Whistles when boiling tea water'},
    {'word': 'RIBBON', 'cat': 'CRAFTS', 'emoji': '🎀', 'clue': 'Silk strip tying celebratory gifts'},
    {'word': 'JACKET', 'cat': 'CLOTHES', 'emoji': '🧥', 'clue': 'Zipped outerwear for cool evenings'},
    {'word': 'BANNER', 'cat': 'FESTIVAL', 'emoji': '🚩', 'clue': 'Hanging fabric displaying slogans'},
    {'word': 'PUZZLE', 'cat': 'GAMES', 'emoji': '🧩', 'clue': 'Jigsaw interlocking challenge'},
    {'word': 'SHIELD', 'cat': 'DEFENSE', 'emoji': '🛡️', 'clue': 'Armor plate deflecting blows'},
    {'word': 'HELMET', 'cat': 'SAFETY', 'emoji': '🪖', 'clue': 'Hard cap guarding the skull'},
    {'word': 'ANCHOR', 'cat': 'NAUTICAL', 'emoji': '⚓', 'clue': 'Heavy iron hook holding ships fast'},
    {'word': 'CANYON', 'cat': 'GEOGRAPHY', 'emoji': '🏜️', 'clue': 'Deep ravine carved by rushing river'},
    {'word': 'DESERT', 'cat': 'BIOMES', 'emoji': '🏜️', 'clue': 'Vast arid expanse of sand dunes'},
    {'word': 'VALLEY', 'cat': 'GEOGRAPHY', 'emoji': '🏞️', 'clue': 'Lowland nestled between green peaks'},
    {'word': 'STREAM', 'cat': 'NATURE', 'emoji': '🫧', 'clue': 'Narrow bubbling freshwater brook'},
    {'word': 'MEADOW', 'cat': 'NATURE', 'emoji': '🌾', 'clue': 'Grassy field blanketed in wildflowers'},
    {'word': 'AURORA', 'cat': 'NIGHT', 'emoji': '🌌', 'clue': 'Shimmering polar light spectacle'},
    {'word': 'COSMOS', 'cat': 'SPACE', 'emoji': '🪐', 'clue': 'Harmonious universe of nebulae'},
    {'word': 'METEOR', 'cat': 'SPACE', 'emoji': '☄️', 'clue': 'Shooting star streaking across night'},
    {'word': 'FARMER', 'cat': 'PEOPLE', 'emoji': '🧑‍🌾', 'clue': 'Tills the land to harvest crops'},
    {'word': 'SAILOR', 'cat': 'NAUTICAL', 'emoji': '🧑‍✈️', 'clue': 'Navigates ships across rough waves'},
  ];

  // ==========================================
  // TIER 5: 7-LETTER WORDS (Levels 141 - 240) - 75 Words
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
    {'word': 'LEOPARD', 'cat': 'SAFARI', 'emoji': '🐆', 'clue': 'Graceful spotted tree-climbing cat'},
    {'word': 'BUFFALO', 'cat': 'WILDLIFE', 'emoji': '🦬', 'clue': 'Massive horned beast of prairies'},
    {'word': 'GORILLA', 'cat': 'WILDLIFE', 'emoji': '🦍', 'clue': 'Gentle giant ape of misty forests'},
    {'word': 'OSTRICH', 'cat': 'BIRDS', 'emoji': '🦤', 'clue': 'Tall flightless bird of savannas'},
    {'word': 'SPARROW', 'cat': 'BIRDS', 'emoji': '🐦', 'clue': 'Small brown songbird on fences'},
    {'word': 'AVOCADO', 'cat': 'FRUITS', 'emoji': '🥑', 'clue': 'Creamy green superfood with pit'},
    {'word': 'APRICOT', 'cat': 'FRUITS', 'emoji': '🍑', 'clue': 'Golden-orange velvety sweet fruit'},
    {'word': 'PUMPKIN', 'cat': 'GARDEN', 'emoji': '🎃', 'clue': 'Carved orange winter squash'},
    {'word': 'SPINACH', 'cat': 'VEGGIES', 'emoji': '🥬', 'clue': 'Iron-rich leafy green superfood'},
    {'word': 'PANCAKE', 'cat': 'BREAKFAST', 'emoji': '🥞', 'clue': 'Flat round griddle cake with syrup'},
    {'word': 'DESSERT', 'cat': 'SWEETS', 'emoji': '🍰', 'clue': 'Sweet finale to a sumptuous meal'},
    {'word': 'VIOLIST', 'cat': 'MUSIC', 'emoji': '🎻', 'clue': 'Musician playing the bow strings'},
    {'word': 'DRUMMER', 'cat': 'MUSIC', 'emoji': '🥁', 'clue': 'Percussionist setting the beat'},
    {'word': 'ECLIPSE', 'cat': 'ASTRONOMY', 'emoji': '🌒', 'clue': 'Moon obscuring light of the sun'},
    {'word': 'HORIZON', 'cat': 'NATURE', 'emoji': '🌅', 'clue': 'Distant line where earth meets sky'},
    {'word': 'SUNRISE', 'cat': 'DAWN', 'emoji': '🌅', 'clue': 'Morning break of radiant dawn light'},
    {'word': 'TORNADO', 'cat': 'STORMS', 'emoji': '🌪️', 'clue': 'Violent spinning funnel of wind'},
    {'word': 'TSUNAMI', 'cat': 'OCEAN', 'emoji': '🌊', 'clue': 'Gigantic seismic ocean tidal wave'},
    {'word': 'ICEBERG', 'cat': 'ARCTIC', 'emoji': '🧊', 'clue': 'Colossal mountain of floating ice'},
    {'word': 'KINGDOM', 'cat': 'HERITAGE', 'emoji': '👑', 'clue': 'Realm governed by a reigning crown'},
    {'word': 'MANSION', 'cat': 'HOUSES', 'emoji': '🏛️', 'clue': 'Stately grand luxurious residence'},
    {'word': 'AIRPORT', 'cat': 'AVIATION', 'emoji': '🛫', 'clue': 'Terminal where airliners depart'},
    {'word': 'HIGHWAY', 'cat': 'TRANSIT', 'emoji': '🛣️', 'clue': 'Multilane arterial transit express'},
    {'word': 'COMPASS', 'cat': 'NAVIGATION', 'emoji': '🧭', 'clue': 'Magnetic needle pointing to north'},
    {'word': 'JEWELRY', 'cat': 'LUXURY', 'emoji': '💍', 'clue': 'Adornments of gold and gems'},
    {'word': 'EMERALD', 'cat': 'GEMS', 'emoji': '💚', 'clue': 'Precious vivid green gemstone'},
    {'word': 'COSTUME', 'cat': 'THEATER', 'emoji': '🎭', 'clue': 'Disguise worn for masquerade or play'},
    {'word': 'PAJAMAS', 'cat': 'SLEEP', 'emoji': '🛌', 'clue': 'Comfortable garments for slumber'},
    {'word': 'SWEATER', 'cat': 'CLOTHES', 'emoji': '🧶', 'clue': 'Knitted wool pull-over for autumn'},
    {'word': 'PAINTER', 'cat': 'ARTS', 'emoji': '🎨', 'clue': 'Artist creating portraits with brush'},
    {'word': 'ATHLETE', 'cat': 'SPORTS', 'emoji': '🏃', 'clue': 'Competitor trained in agility & speed'},
    {'word': 'EXPLORER', 'cat': 'VOYAGES', 'emoji': '🧭', 'clue': 'Venturer charting untrodden realms'},
    {'word': 'WARRIOR', 'cat': 'HEROES', 'emoji': '⚔️', 'clue': 'Brave defender wielding valiant shield'},
    {'word': 'FORTUNE', 'cat': 'WEALTH', 'emoji': '💰', 'clue': 'Great prosperity of golden riches'},
    {'word': 'VICTORY', 'cat': 'SUCCESS', 'emoji': '🏆', 'clue': 'Triumph won after noble struggle'},
    {'word': 'BICYCLE', 'cat': 'TRANSPORT', 'emoji': '🚲', 'clue': 'Two-wheeled pedal-powered ride'},
    {'word': 'SCOOTER', 'cat': 'TRANSIT', 'emoji': '🛴', 'clue': 'Step-on handlebar commute wheel'},
    {'word': 'SUNSHINE', 'cat': 'DAYLIGHT', 'emoji': '☀️', 'clue': 'Warm radiant morning light'},
    {'word': 'FIREFLY', 'cat': 'INSECTS', 'emoji': '🪲', 'clue': 'Nocturnal beetle that glows'},
    {'word': 'CRYSTAL', 'cat': 'MINERALS', 'emoji': '💎', 'clue': 'Sparkling clear mineral rock'},
    {'word': 'DOLPHIN', 'cat': 'OCEAN', 'emoji': '🐬', 'clue': 'Friendly mammal leaping in surf'},
    {'word': 'GARDNER', 'cat': 'OUTDOORS', 'emoji': '🧑‍🌾', 'clue': 'Tends flowers and green foliage'},
    {'word': 'PIRATES', 'cat': 'ADVENTURE', 'emoji': '🏴‍☠️', 'clue': 'Crew sailing in search of booty'},
    {'word': 'CAROUSEL', 'cat': 'CARNIVAL', 'emoji': '🎠', 'clue': 'Merry-go-round with wooden ponies'},
    {'word': 'GALAXY', 'cat': 'SPACE', 'emoji': '🌌', 'clue': 'Massive cosmic spiral system'},
  ];

  // ==========================================
  // TIER 6: 8-LETTER WORDS (Levels 241+) - 70 Words
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
    {'word': 'ANTELOPE', 'cat': 'SAFARI', 'emoji': '🦌', 'clue': 'Swift graceful horned gazelle'},
    {'word': 'HEDGEHOG', 'cat': 'WILDLIFE', 'emoji': '🦔', 'clue': 'Quilled small spiny woodland ball'},
    {'word': 'REINDEER', 'cat': 'ARCTIC', 'emoji': '🦌', 'clue': 'Antlered Arctic herd pulling sleds'},
    {'word': 'STALLION', 'cat': 'ANIMALS', 'emoji': '🐎', 'clue': 'Spirited uncastrated adult horse'},
    {'word': 'SUNFLOWER', 'cat': 'FLOWERS', 'emoji': '🌻', 'clue': 'Towering blossom turning to sun'},
    {'word': 'PINEAPPLE', 'cat': 'FRUITS', 'emoji': '🍍', 'clue': 'Prickly crown tropical golden fruit'},
    {'word': 'CUCUMBER', 'cat': 'VEGGIES', 'emoji': '🥒', 'clue': 'Cool green salad vine crop'},
    {'word': 'BROCCOLI', 'cat': 'VEGGIES', 'emoji': '🥦', 'clue': 'Nutritious green tree-like vegetable'},
    {'word': 'ORCHESTRA', 'cat': 'MUSIC', 'emoji': '🎻', 'clue': 'Symphonic ensemble of instruments'},
    {'word': 'TROMBONE', 'cat': 'MUSIC', 'emoji': '🎺', 'clue': 'Brass horn with sliding tube'},
    {'word': 'ASTEROID', 'cat': 'SPACE', 'emoji': '☄️', 'clue': 'Rocky fragment orbiting interplanetary'},
    {'word': 'SPACESHIP', 'cat': 'SCI-FI', 'emoji': '🚀', 'clue': 'Vessel traversing cosmic constellations'},
    {'word': 'BLIZZARD', 'cat': 'WINTER', 'emoji': '🌨️', 'clue': 'Blinding winter snowstorm gales'},
    {'word': 'AQUARIUM', 'cat': 'OCEAN', 'emoji': '🐠', 'clue': 'Glass habitat displaying marine fauna'},
    {'word': 'WINDMILL', 'cat': 'ENERGY', 'emoji': '🌬️', 'clue': 'Rotating vanes harvesting gusts of air'},
    {'word': 'FIREPLACE', 'cat': 'HEARTH', 'emoji': '🪵', 'clue': 'Warm stone hearth crackling with logs'},
    {'word': 'NOTEBOOK', 'cat': 'STUDY', 'emoji': '📓', 'clue': 'Bound sheets for penning thoughts'},
    {'word': 'UMBRELLA', 'cat': 'RAIN', 'emoji': '☂️', 'clue': 'Canopy sheltering from torrential rain'},
    {'word': 'NECKLACE', 'cat': 'JEWELRY', 'emoji': '📿', 'clue': 'Ornamental chain encircling collar'},
    {'word': 'RAINCOAT', 'cat': 'CLOTHES', 'emoji': '🧥', 'clue': 'Waterproof coat for storm showers'},
    {'word': 'SNEAKERS', 'cat': 'SHOES', 'emoji': '👟', 'clue': 'Rubber-soled athletic casual footwear'},
    {'word': 'MARATHON', 'cat': 'RACES', 'emoji': '🏃', 'clue': 'Endurance race spanning many miles'},
    {'word': 'CLIMBING', 'cat': 'OUTDOORS', 'emoji': '🧗', 'clue': 'Ascending sheer vertical cliff faces'},
    {'word': 'GARDENER', 'cat': 'OUTDOORS', 'emoji': '🧑‍🌾', 'clue': 'Cares for blossoming garden beds'},
    {'word': 'ASTRONAUT', 'cat': 'SPACE', 'emoji': '🧑‍🚀', 'clue': 'Space explorer floating in orbit'},
    {'word': 'CAROUSEL', 'cat': 'CARNIVAL', 'emoji': '🎠', 'clue': 'Carnival ride with music & lights'},
    {'word': 'FESTIVAL', 'cat': 'CELEBRATE', 'emoji': '🎉', 'clue': 'Joyous communal celebration day'},
    {'word': 'LEMONADE', 'cat': 'DRINKS', 'emoji': '🍋', 'clue': 'Chilled sweet & sour summer drink'},
    {'word': 'SURPRISE', 'cat': 'JOY', 'emoji': '🎁', 'clue': 'Unexpected delightful wonder'},
    {'word': 'SMILING', 'cat': 'HAPPINESS', 'emoji': '😁', 'clue': 'Grinning with joyful delight'},
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
  /// Uses cycle-based non-repeating permutations so all words in a tier are
  /// played before any word repeats, ensuring huge variety across levels!
  static BalloonPuzzle getPuzzleForLevel(int level) {
    final wordLength = getWordLengthForLevel(level);
    final wordList = _getWordListForLength(wordLength);

    // Guaranteed non-repeating cycle permutation:
    // For each cycle of wordList.length levels, generate a deterministic shuffle
    // seeded by the tier length and cycle index.
    final cycle = (level - 1) ~/ wordList.length;
    final indexInCycle = (level - 1) % wordList.length;
    final perm = List<int>.generate(wordList.length, (i) => i);
    perm.shuffle(math.Random(wordLength * 9973 + cycle * 7919 + 31));
    final itemIndex = perm[indexInCycle];
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
