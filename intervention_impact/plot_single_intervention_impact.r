library(data.table)
library(ggplot2)
library(gridExtra)

rm(list=ls())

gg_color_hue <- function(n) {
  hues = seq(15, 375, length = n + 1)
  hcl(h = hues, l = 65, c = 100)[1:n]
}
colors <- gg_color_hue(5)[2:5]

main_dir <- file.path(Sys.getenv("USERPROFILE"), 
                      "Dropbox (IDM)/Malaria Team Folder/projects/map_intervention_impact/lookup_tables")


initial <- fread(file.path(main_dir, "initial", "initial_het_biting.csv"))
# explore distribution of initial prevalences
ggplot(initial, aes(x=log10(x_Temporary_Larval_Habitat), y=initial_prev)) +
  geom_point() +
  facet_wrap(~Site_Name)

files <- list.files(file.path(main_dir, "interactions"), full.names = T)

all_data <- lapply(files, fread)
all_data <- rbindlist(all_data, fill=T)
all_data[, Intervention:=""]


for (int in c("ITN", "IRS", "ACT")){
  varname = paste0(int, "_Coverage")
  all_data[get(varname)!=0, Intervention:= paste0(Intervention, int, " ", get(varname), "; ") ]
}

all_data[Intervention=="", Intervention:="None"]
all_data <- merge(all_data, initial, by=c("Site_Name", "Run_Number", "x_Temporary_Larval_Habitat"), all=T)

all_data[, Run_Number:=factor(Run_Number)]
all_data[, mean_initial:= mean(initial_prev), by=list(Site_Name, x_Temporary_Larval_Habitat, Intervention)]
all_data[, mean_final:=mean(final_prev), by=list(Site_Name, x_Temporary_Larval_Habitat, Intervention)]

write.csv(all_data, file=file.path(main_dir, "interactions", "lookup_full_interactions.csv"), row.names = F)





ggplot(int_data[Intervention=="ACT" & Site_Name=="martae"], aes(x=initial_prev, y=final_prev, color=Coverage)) +
  geom_line(aes(group=interaction(Coverage, Run_Number)), alpha=0.25) +
  geom_line(aes(x=mean_initial, y=mean_final), size=1.5) +
  geom_abline(color=gg_color_hue(5)[1], size=1.5)+
  scale_color_manual(values=colors) + 
  theme_minimal() +
  labs(x="Initial PfPR",
       y="Final PfPR",
       title="ACT Impact by Daily Prob of Care-Seeking, Martae, Cameroon") +
  facet_grid(~ACT_HS_Rate)

# png(file.path(main_dir, "itn", "baseline_itn.png"), width=800, height=650, res=160)
ggplot(int_data[Intervention=="ITN" & Hates_Nets==0], aes(x=initial_prev, y=final_prev, color=Coverage)) +
  geom_line(aes(group=interaction(Coverage, Run_Number)), alpha=0.25) + 
  geom_line(aes(x=mean_initial, y=mean_final), size=1.5) +
  scale_color_manual(values=colors) + 
  geom_abline(color=gg_color_hue(5)[1], size=1.5)+
  theme_minimal() + 
  labs(x="Initial PfPR",
       y="Final PfPR",
       title="ITN Impact, Heterogeneous Biting") + 
  facet_wrap(~Site_Name)

# graphics.off()



