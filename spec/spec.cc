/* Lama SM Bytecode interpreter */

# include <cstring>
# include <cstdio>
# include <cerrno>
# include <string>
# include <sstream>

extern "C" char* sexp_string_buffer;

void *__start_custom_data;
void *__stop_custom_data;

/* The unpacked representation of bytecode file */
struct bytefile {
  char *string_ptr;              /* A pointer to the beginning of the string table */
  int  *public_ptr;              /* A pointer to the beginning of publics table    */
  char *code_ptr;                /* A pointer to the bytecode itself               */
  int  *global_ptr;              /* A pointer to the global area                   */
  int   stringtab_size;          /* The size (in bytes) of the string table        */
  int   global_area_size;        /* The size (in words) of global area             */
  int   public_symbols_number;   /* The number of public symbols                   */
  char*  buffer;
};

/* Gets a string from a string table by an index */
char* get_string (bytefile *f, int pos) {
  return &f->string_ptr[pos];
}

/* Gets a name for a public symbol */
char* get_public_name (bytefile *f, int i) {
  return get_string (f, f->public_ptr[i*2]);
}

/* Gets an offset for a publie symbol */
int get_public_offset (bytefile *f, int i) {
  return f->public_ptr[i*2+1];
}

/* Reads a binary bytecode file by name and unpacks it */
bytefile* read_file (const char *fname) {
  FILE *f = std::fopen (fname, "rb");
  std::size_t size;
  bytefile *file;

  file = new bytefile{};

  std::fseek (f, 0, SEEK_END);
  size = std::ftell(f);
  char* buff = new char[size - 3 * sizeof(int)];

  //file = (bytefile*) malloc (sizeof(int)*4 + (size = ftell (f)));

  std::rewind (f);

  file->buffer = buff;
  std::fread(&file->stringtab_size, sizeof(int), 1, f);
  std::fread(&file->global_area_size, sizeof(int), 1, f);
  std::fread(&file->public_symbols_number, sizeof(int), 1, f);
  std::fread(buff, 1, size - 3 * sizeof(int), f);

  std::fclose (f);

  file->string_ptr  = &file->buffer [file->public_symbols_number * 2 * sizeof(int)];
  file->public_ptr  = (int*)(file->buffer);
  file->code_ptr    = &file->string_ptr [file->stringtab_size];
  file->global_ptr  = new int[file->global_area_size];

  return file;
}

/* Disassembles the bytecode pool */
void disassemble (FILE *f, bytefile *bf) {

# define INT    (ip += sizeof (int), *(int*)(ip - sizeof (int)))
# define BYTE   *ip++
# define STRING get_string (bf, INT)

  char *ip     = bf->code_ptr;
  const char *ops [] = {"+", "-", "*", "/", "%", "<", "<=", ">", ">=", "==", "!=", "&&", "!!"};
  const char *pats[] = {"=str", "#string", "#array", "#sexp", "#ref", "#val", "#fun"};
  const char *lds [] = {"LD", "LDA", "ST"};
  std::stringstream ss;

  auto emit_code = [&ss] (const std::string &s) {
    ss << s;
  };

  auto gen_label = [] (int offset) {
    std::stringstream meow;
    meow << "Label_" << std::hex << offset;
    return meow.str();
  };

  emit_code(R"(
	.macro FIX_UNB dst
	xorl 	$1, \dst
	sarl 	$1, \dst
	.endm

	.macro	POP dst
	subl	$4, %esi
	movl	(%esi), \dst
	.endm

	.macro	POP2 dst1 dst2
	POP	\dst1
	POP	\dst2
	.endm

	.macro	PUSH dst
	movl	\dst, (%esi)
	addl	$4, %esi
	.endm
  )");

  do {
    char x = BYTE,
         h = (x & 0xF0) >> 4,
         l = x & 0x0F;

    std::fprintf (f, "0x%.8x:\t%.2x %.2x\t", ip-bf->code_ptr-1, h, l);
    emit_code(gen_label(ip - bf->code_ptr - 1) + ":\n");

    switch (h) {
    case 15:
      goto stop;

    /* BINOP */
    case 0:
      emit_code(R"(
	POP2 	%eax %ebx
	FIX_UNB %eax
	FIX_UNB %ebx
  )");
      switch (l) {
        case 0:
        emit_code(R"(
	addl	%eax, %ebx
        )");
        break;
        case 1:
        emit_code(R"(
	subl	%eax, %ebx
        )");
        break;
        case 2: // mul
        emit_code(R"(
	imul	%ebx
        )");
        break;
        case 3: // div
        case 4: // mod
        emit_code(R"(
	cltd
	idiv	%ebx
        )");
        break;
        case 11: // and
        emit_code(R"(
	andl	%ebx, %eax
        )");
        break;
        case 12: // or
        emit_code(R"(
	orl		%ebx, %eax
        )");
        break;
        case 5: // eq
        case 6: // neq
        case 7: // lt
        case 8: // le
        case 9: // gt
        case 10: // ge
        emit_code(R"(
	xorl	%edx, %edx
	cmpl	%eax, %ebx
        )");
        break;
      }
      switch (l) {
        case 0: // add
        case 1: // sub
        case 2: // mul
        case 11: // and
        case 12: // or
        emit_code(R"(
  FIX_BOX %eax
  PUSH	%eax
        )");
        break;
        case 3: // div
        emit_code(R"(
	FIX_BOX %eax
	PUSH	%eax
        )");
        break;
        case 4: // mod
        emit_code(R"(
	FIX_BOX %edx
	PUSH	%edx
        )");
        break;
        case 5: // eq
        emit_code(R"(
	seteb	%dl
        )");
        break;
        case 6: // neq
        emit_code(R"(
	setneb	%dl
        )");
        break;
        case 7: // lt
        emit_code(R"(
	setlb	%dl
        )");
        break;
        case 8: // le
        emit_code(R"(
	setleb	%dl
        )");
        break;
        case 9: // gt
        emit_code(R"(
	setgb	%dl
        )");
        break;
        case 10: // ge
        emit_code(R"(
	setgeb	%dl
        )");
        break;
      }
      switch (l) {
        case 5: // eq
        case 6: // neq
        case 7: // lt
        case 8: // le
        case 9: // gt
        case 10: // ge
        emit_code(R"(
	FIX_BOX %edx
	PUSH	%edx
        )");
        break;
      }
      break;

    case 1:
      switch (l) {
      case  0:
        std::fprintf (f, "CONST\t%d", INT);
        break;

      case  1:
        std::fprintf (f, "STRING\t%s", STRING);
        break;

      case  2:
        std::fprintf (f, "SEXP\t%s ", STRING);
        std::fprintf (f, "%d", INT);
        break;

      case  3:
        std::fprintf (f, "STI");
        break;

      case  4:
        std::fprintf (f, "STA");
        break;

      case  5:
        std::fprintf (f, "JMP\t0x%.8x", INT);
        break;

      case  6:
        std::fprintf (f, "END");
        break;

      case  7:
        std::fprintf (f, "RET");
        break;

      case  8:
        std::fprintf (f, "DROP");
        break;

      case  9:
        std::fprintf (f, "DUP");
        break;

      case 10:
        std::fprintf (f, "SWAP");
        break;

      case 11:
        std::fprintf (f, "ELEM");
        break;
      }
      break;

    case 2:
    case 3:
    case 4:
      std::fprintf (f, "%s\t", lds[h-2]);
      switch (l) {
      case 0: std::fprintf (f, "G(%d)", INT); break;
      case 1: std::fprintf (f, "L(%d)", INT); break;
      case 2: std::fprintf (f, "A(%d)", INT); break;
      case 3: std::fprintf (f, "C(%d)", INT); break;
      }
      break;

    case 5:
      switch (l) {
      case  0:
        std::fprintf (f, "CJMPz\t0x%.8x", INT);
        break;

      case  1:
        std::fprintf (f, "CJMPnz\t0x%.8x", INT);
        break;

      case  2:
        std::fprintf (f, "BEGIN\t%d ", INT);
        std::fprintf (f, "%d", INT);
        break;

      case  3:
        std::fprintf (f, "CBEGIN\t%d ", INT);
        std::fprintf (f, "%d", INT);
        break;

      case  4:
        std::fprintf (f, "CLOSURE\t0x%.8x", INT);
        {int n = INT;
         for (int i = 0; i<n; i++) {
         switch (BYTE) {
           case 0: std::fprintf (f, "G(%d)", INT); break;
           case 1: std::fprintf (f, "L(%d)", INT); break;
           case 2: std::fprintf (f, "A(%d)", INT); break;
           case 3: std::fprintf (f, "C(%d)", INT); break;
         }
         }
        };
        break;

      case  5:
        std::fprintf (f, "CALLC\t%d", INT);
        break;

      case  6:
        std::fprintf (f, "CALL\t0x%.8x ", INT);
        std::fprintf (f, "%d", INT);
        break;

      case  7:
        std::fprintf (f, "TAG\t%s ", STRING);
        std::fprintf (f, "%d", INT);
        break;

      case  8:
        std::fprintf (f, "ARRAY\t%d", INT);
        break;

      case  9:
        std::fprintf (f, "FAIL\t%d", INT);
        std::fprintf (f, "%d", INT);
        break;

      case 10:
        std::fprintf (f, "LINE\t%d", INT);
        break;
      }
      break;

    case 6:
      std::fprintf (f, "PATT\t%s", pats[l]);
      break;

    case 7: {
      switch (l) {
      case 0:
        std::fprintf (f, "CALL\tLread");
        break;

      case 1:
        emit_code(R"(
	POP		%ebx
	pushl	%ebx
	call	Lwrite
	popl	%ebx
	FIX_BOX	%eax
	PUSH	%eax
        )");
        break;

      case 2:
        std::fprintf (f, "CALL\tLlength");
        break;

      case 3:
        std::fprintf (f, "CALL\tLstring");
        break;

      case 4:
        std::fprintf (f, "CALL\tBarray\t%d", INT);
        break;
      }
    }
    break;
    }

    std::fprintf (f, "\n");
  }
  while (1);
 stop: std::fprintf (f, "<end>\n");
}

/* Dumps the contents of the file */
void dump_file (FILE *f, bytefile *bf) {
  int i;

  std::fprintf (f, "String table size       : %d\n", bf->stringtab_size);
  std::fprintf (f, "Global area size        : %d\n", bf->global_area_size);
  std::fprintf (f, "Number of public symbols: %d\n", bf->public_symbols_number);
  std::fprintf (f, "Public symbols          :\n");

  for (i=0; i < bf->public_symbols_number; i++)
    std::fprintf (f, "   0x%.8x: %s\n", get_public_offset (bf, i), get_public_name (bf, i));

  std::fprintf (f, "Code:\n");
  disassemble (f, bf);
}

int main (int argc, const char* argv[]) {
  bytefile *f = read_file (argv[1]);
  dump_file (stderr, f);

  delete f->global_ptr;
  delete f->buffer;
  delete f;
}
