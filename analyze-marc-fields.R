require(data.table)
require(ggplot2)
data =fread("count-fields-full.tsv", header=F, colClasses = c("character", "character"))
colnames(data) <- c("Record", "Field")

ref <- fread("marc-ref.tsv", header = T, colClasses = c("character", "character"))

# Count Fields that occur in the most records
countfields <- data[, list(count=length(unique(Record))), by=list(Field)][order(-count)]
countfields[['percentage']] <- 100*countfields[['count']]/100000

# Cross-reference with description
merge(countfields, ref, by="Field", all.x=T)[order(-count)]

# Show Distribution
ggplot(countfields, aes(x=1:123, y=count)) + geom_point()

# See also which fields occur the most (included duplicates per record)
data[, list(count=.N), by=list(Field)][order(-count)]

# See which of the sample records has the most control fields (to use as an example)
data[, list(Unique.Fields=length(unique(Field))), by=list(Record)][order(-Unique.Fields)]


a = merge(countfields, ref, by="Field", all.x=T)[order(-count)]
write.csv(a, "top-marc-fields.csv", row.names=F)