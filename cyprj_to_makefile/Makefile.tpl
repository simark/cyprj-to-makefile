CROSS = {{ cross }}
CC = $(CROSS)-gcc
AR = $(CROSS)-ar
AS = $(CROSS)-as

{% set c_objs = visitor.source_files['C_FILE'] | map('basename') | map('replace_ext', 'o') | map('prefix', '/') | map('prefix', objdir) | join(' ') %}
{% set arm_c_objs = visitor.source_files['ARM_C_FILE'] | map('basename') | map('replace_ext', 'o') | map('prefix', '/') | map('prefix', objdir) | join(' ') %}
{% set gnu_arm_asm_objs = visitor.source_files['GNU_ARM_ASM_FILE'] | map('basename') | map('replace_ext', 'o') | map('prefix', '/') | map('prefix', objdir) | join(' ') %}

CFLAGS = {{ visitor.additional_cflags | join(' ') }}

.PHONY: all
all: {{ objdir }}/{{ projname }}.elf

.PHONY: clean
clean:
	rm -f \
	  {{ c_objs }} \
	  {{ arm_c_objs }} \
	  {{ gnu_arm_asm_objs }} \
	   {{ objdir }}/{{ projname }}.a \
	  {{ objdir }}/{{ projname }}.elf

# ELF file

{{ objdir }}/{{ projname }}.elf: {{ c_objs }} {{ arm_c_objs }} {{ gnu_arm_asm_objs }}
	$(CC) -Wl,--start-group -o {{ objdir }}/{{ projname }}.elf \
	  {{ c_objs }} {{ arm_c_objs }} {{ gnu_arm_asm_objs }} CyComponentLibrary.a \
	  -mcpu=cortex-m3 -mthumb -g -ffunction-sections -Og -L Generated_Source/PSoC5 \
	  -Wl,-Map,{{ objdir }}/{{ projname }}.map -T Generated_Source/PSoC5/cm3gcc.ld \
	  -specs=nano.specs -Wl,--gc-sections -Wl,--end-group

# Archive

{{ objdir }}/{{ projname }}.a: {{ c_objs }} {{ arm_c_objs }} {{ gnu_arm_asm_objs }}
	$(AR) -rs {{ objdir }}/{{ projname }}.a {{ c_objs }} {{ arm_c_objs }} {{ gnu_arm_asm_objs }}

# C files
{% for c_file in visitor.source_files['C_FILE'] %}
{{ objdir }}/{{ c_file | basename | replace_ext('o') }}: {{ c_file }}
	$(CC) -mcpu=cortex-m3 -mthumb -Wno-main {{ visitor.include_dirs | map('prefix', '-I') | join(' ') }} -I. -IGenerated_Source/PSoC5 \
	  -Wa,-alh={{ objdir }}/{{ c_file | basename | replace_ext('lst') }} -g -D DEBUG $(CFLAGS) -ffunction-sections -Og -ffat-lto-objects -c \
	  {{ c_file }} -o {{ objdir }}/{{ c_file | basename | replace_ext('o') }}
{% endfor %}

# ARM C files
{% for arm_c_file in visitor.source_files['ARM_C_FILE'] %}
{{ objdir }}/{{ arm_c_file | basename | replace_ext('o') }}: {{ arm_c_file }}
	$(CC) -mcpu=cortex-m3 -mthumb -Wno-main {{ visitor.include_dirs | map('prefix', '-I') | join(' ') }} -I. -IGenerated_Source/PSoC5 \
	  -Wa,-alh={{ objdir }}/{{ arm_c_file | basename | replace_ext('lst') }} -g -D DEBUG $(CFLAGS) -ffunction-sections -Og -ffat-lto-objects -c \
	  {{ arm_c_file }} -o {{ objdir }}/{{ arm_c_file | basename | replace_ext('o') }}
{% endfor %}

# GNU ARM ASM files
{% for gnu_arm_asm_file in visitor.source_files['GNU_ARM_ASM_FILE'] %}
{{ objdir }}/{{ gnu_arm_asm_file | basename | replace_ext('o') }}: {{ gnu_arm_asm_file }}
	$(AS) -mcpu=cortex-m3 -mthumb -I. -IGenerated_Source/PSoC5 -alh={{ objdir }}/{{ gnu_arm_asm_file | basename | replace_ext('lst') }} -g -W \
	  -o {{ objdir }}/{{ gnu_arm_asm_file | basename | replace_ext('o') }} {{ gnu_arm_asm_file }}
{% endfor %}