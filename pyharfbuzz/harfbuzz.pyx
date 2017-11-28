from . cimport charfbuzz

__all__ = [
    'FTLibrary',
    'FTFace',
    'HBFontT',
    'HBBufferT',
    'hb_shape',
    'get_glyph_name',
    'hb_buffer_get_direction',
    'is_horizontal',
    'is_ltr', 'is_rtl', 'is_ttb', 'is_btt'
]
    

cdef class FTLibrary:
    cdef charfbuzz.FT_Library ft_library
    def init(self):
        error = charfbuzz.FT_Init_FreeType(&self.ft_library)
        if error:
            raise Exception("Freetype library cant be initilized.")


cdef class FTFace:
    cdef charfbuzz.FT_Face ft_face
    cdef const char* cfont_name
    def init(self, FTLibrary ftl, font_name):
        if isinstance(font_name, str):
            font_name = font_name.encode('utf-8')
        self.cfont_name = font_name

        error = charfbuzz.FT_New_Face(ftl.ft_library, self.cfont_name, 0, &self.ft_face)
        if error:
            raise Exception("Freetype face cant be initilized.")

    def set_charsize(self, char_size):
        error = charfbuzz.FT_Set_Char_Size(self.ft_face, char_size, char_size, 0, 0)
        if error:
            raise Exception("Freetype cant set char size initilized.")


cdef class HBFontT:
    cdef charfbuzz.hb_font_t *hb_font_t
    def hb_ft_font_create(self, FTFace ftf):
        self.hb_font_t = charfbuzz.hb_ft_font_create(ftf.ft_face, NULL)

    def __dealloc__(self):
        charfbuzz.hb_font_destroy(self.hb_font_t)


cdef class HBBufferT:
    cdef charfbuzz.hb_buffer_t *hb_buffer_t

    def __cinit__(self):
        self.hb_buffer_create()

    def hb_buffer_create(self):
        self.hb_buffer_t = charfbuzz.hb_buffer_create()

    def hb_buffer_add_utf8(self, text, text_length, item_offset, item_length):
        if isinstance(text, str):
            text = text.encode('utf-8')

        cdef const char *ctext = text
        cdef int ctext_length = text_length

        charfbuzz.hb_buffer_add_utf8(self.hb_buffer_t, ctext,
            ctext_length, item_offset, item_length)

    def guess_segment_properties(self):
        charfbuzz.hb_buffer_guess_segment_properties(self.hb_buffer_t)

    def get_length(self):
        return charfbuzz.hb_buffer_get_length(self.hb_buffer_t)

    def get_glyph_infos(self):
        glyph_info = HBGlyphInfoT()
        glyph_info.set_hb_glyph_info(self.hb_buffer_t)
        return glyph_info

    def get_glyph_position(self):
        glyph_position = HBGlyphPositionT()
        glyph_position.set_hb_glyph_positions(self.hb_buffer_t)
        return glyph_position

    def __dealloc__(self):
        charfbuzz.hb_buffer_destroy(self.hb_buffer_t)


cdef class HBFeatureT:
    cdef charfbuzz.hb_feature_t *hb_feature_t


cdef class HBGlyphInfoT:
    cdef charfbuzz.hb_glyph_info_t *hb_glyph_info_t
    cdef set_hb_glyph_info(self, charfbuzz.hb_buffer_t * buffer):
        cdef charfbuzz.hb_glyph_info_t *hb_glyph_info_t = charfbuzz.hb_buffer_get_glyph_infos(buffer, NULL)
        self.hb_glyph_info_t = hb_glyph_info_t

    def __getitem__(self, x):
        return self.hb_glyph_info_t[x]


cdef class HBGlyphPositionT:
    cdef charfbuzz.hb_glyph_position_t *hb_glyph_position_t
    cdef set_hb_glyph_positions(self, charfbuzz.hb_buffer_t * buffer):
        cdef charfbuzz.hb_glyph_position_t *hb_glyph_position_t = charfbuzz.hb_buffer_get_glyph_positions(buffer, NULL)
        self.hb_glyph_position_t = hb_glyph_position_t

    def __getitem__(self, x):
        return self.hb_glyph_position_t[x]


def hb_shape(HBFontT font, HBBufferT buffer, HBFeatureT feature, num_features):
    charfbuzz.hb_shape(font.hb_font_t, buffer.hb_buffer_t, feature.hb_feature_t, num_features)

def get_glyph_name(HBFontT font, codepoint):
    cdef char glyph_name[32]
    charfbuzz.hb_font_get_glyph_name(font.hb_font_t, codepoint, glyph_name, sizeof(glyph_name))
    return glyph_name

def hb_buffer_get_direction(HBBufferT buffer):
    return charfbuzz.hb_buffer_get_direction(buffer.hb_buffer_t)

def is_ltr(HBBufferT buffer):
    if hb_buffer_get_direction(buffer) == 4:
        return True
    return False

def is_rtl(HBBufferT buffer):
    if hb_buffer_get_direction(buffer) == 5:
        return True
    return False

def is_ttb(HBBufferT buffer):
    if hb_buffer_get_direction(buffer) == 6:
        return True
    return False

def is_btt(HBBufferT buffer):
    if hb_buffer_get_direction(buffer) == 7:
        return True
    return False

def is_horizontal(dir_code):
    if (dir_code == 4 or dir_code == 5):
        return True
    return False