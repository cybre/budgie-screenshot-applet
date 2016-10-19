AM_CFLAGS = \
        -fstack-protector -Wall -pedantic \
        -Wstrict-prototypes -Wundef -fno-common \
        -Werror-implicit-function-declaration \
        -Wformat -Wformat-security -Werror=format-security \
        -Wno-conversion -Wunused-variable -Wunreachable-code \
        -Wall -W -D_FORTIFY_SOURCE=2 -std=c11 -fPIC


DECLARATIONS = \
	-DGETTEXT_PACKAGE=\"$(GETTEXT_PACKAGE)\"
