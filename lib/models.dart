/// Represents a brief song model with the following structure:
/// ```dart
/// {
///    "identifier": "235474087",    // Unique identifier of the song
///    "source": "xxx",          // Source platform of the song
///    "title": "公路之歌 (Live)",     // Title of the song
///    "artists_name": "痛仰乐队",     // Name of the artist(s)
///    "album_name": "乐队的夏天 第11期", // Name of the album
///    "duration_ms": "05:07",       // Duration of the song
///    "provider": "xxx",        // Provider of the song
///    "uri": "fuo://xxx/songs/1111", // URI to access the song
///    "__type__": "feeluown.library.BriefSongModel" // Type identifier
/// }
/// ```
typedef BriefSongModel = Map<String, dynamic>;
