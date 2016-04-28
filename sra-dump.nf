/* 
 * SRA Dump pipeline script
 *
 * @authors
 * Paolo Di Tommaso <paolo.ditommaso@gmail.com>
 * Evan Floden <evanfloden@gmail.com> 
 */

params.name          = "Simple Nextflow Script for Downloading all fastq from a SRA Study Accession"
params.study         = ""
params.sra           = "$baseDir/data/sra/SraRunTable.txt"
params.output        = "results/"

log.info "S R A - D U M P - N F  ~  version 0.1"
log.info "====================================="
log.info "name                   : ${params.name}"
log.info "output                 : ${params.output}"
log.info "\n"


/*
 * Input parameters validation
 */

study_accession_id     = params.study

process parse_sra {

    input:
    val(study_accession) from study_accession_id

    output:
    file ( 'exp_info.txt' ) into experiment_info
    file ( 'sra_list.txt') into sra_list

    //
    // Parse the SRA Run Info file into an experiment info file
    // containing SRR run accesions and conditions
    //
    shell:
    '''
        wget -O SraRunTable.csv 'http://trace.ncbi.nlm.nih.gov/Traces/sra/sra.cgi?save=efetch&db=sra&rettype=runinfo&term=!{study_accession}'

        cut -d, -f 1 SraRunTable.csv > exp_info.txt
        sed '1d' exp_info.txt > tmpfile
        mv tmpfile exp_info.txt
        echo -e "run_accesion" | cat - exp_info.txt > temp_table
        mv temp_table exp_info.txt

        sed '1d' exp_info.txt > sra_list.txt
    '''
}

sra_list
    .splitCsv(header: ['sra_accession'])
    .set { sra_ids }

process download_sra {

    input:
    val(sra_id) from sra_ids

    output:
    set file("${sra_id.sra_accession}_1.fastq.gz"), file("${sra_id.sra_accession}_2.fastq.gz") into sra_read_files

    script:
    """
    echo "Attempting to download ${sra_id.sra_accession}"
    fastq-dump --split-files --gzip ${sra_id.sra_accession} -O .
    """

}
