<template>
  <div class="geo-selector">
    <h4 class="title is-5">{{ $t('geo.title') }}</h4>
    <div class="geo-controls">
      <b-field :label="$t('geo.region')">
        <b-select v-model="selectedRegion" @input="onRegionChange" expanded>
          <option value="">{{ $t('geo.selectRegion') }}</option>
          <option v-for="region in regions" :key="region.region_code" :value="region.region_nom">
            {{ region.region_nom }}
          </option>
        </b-select>
      </b-field>

      <b-field :label="$t('geo.department')">
        <b-select v-model="selectedDepartment" @input="onDepartmentChange" expanded :disabled="!selectedRegion">
          <option value="">{{ $t('geo.selectDepartment') }}</option>
          <option v-for="dept in filteredDepartments" :key="dept.departement_numero" :value="dept.departement_numero">
            {{ dept.departement_nom }} ({{ dept.departement_numero }})
          </option>
        </b-select>
      </b-field>

      <b-field :label="$t('geo.commune')">
        <b-input
          v-model="communeSearch"
          @input="onCommuneSearch"
          :placeholder="$t('geo.searchCommune')"
          expanded
          :disabled="!selectedDepartment"
        />
      </b-field>

      <div v-if="communes.length > 0" class="commune-results">
        <div
          v-for="commune in communes"
          :key="commune.code_insee"
          class="commune-item"
          @click="selectCommune(commune)"
          @keydown.enter="selectCommune(commune)"
          tabindex="0"
          role="button"
        >
          <strong>{{ commune.nom_commune }}</strong> ({{ commune.code_insee }})
          <br>
          <small>Population: {{ commune.population_commune?.toLocaleString() || 'N/A' }}</small>
        </div>
      </div>

      <div class="columns">
        <div class="column">
          <b-field :label="$t('geo.populationMin')">
            <b-input
              v-model="populationMin"
              type="number"
              :placeholder="$t('geo.populationMinPlaceholder')"
            />
          </b-field>
        </div>
        <div class="column">
          <b-field :label="$t('geo.populationMax')">
            <b-input
              v-model="populationMax"
              type="number"
              :placeholder="$t('geo.populationMaxPlaceholder')"
            />
          </b-field>
        </div>
      </div>

      <b-field :label="$t('geo.csp')">
        <b-select v-model="selectedCSP" expanded>
          <option value="">{{ $t('geo.selectCSP') }}</option>
          <option v-for="csp in csps" :key="csp.csp" :value="csp.csp">
            {{ csp.csp }} ({{ csp.count }})
          </option>
        </b-select>
      </b-field>

      <div class="buttons">
        <button type="button" class="button is-primary" @click="testSelection">
          <b-icon icon="magnify" size="is-small" />
          <span>{{ $t('geo.testSelection') }}</span>
        </button>

        <button type="button" class="button is-success" @click="applySelection" :disabled="!hasSelection">
          <b-icon icon="check" size="is-small" />
          <span>{{ $t('geo.applySelection') }}</span>
        </button>

        <button type="button" class="button" @click="clearSelection">
          {{ $t('geo.clear') }}
        </button>
      </div>

      <div v-if="testResult !== null" class="notification" :class="testResult > 0 ? 'is-success' : 'is-warning'">
        {{ $t('geo.testResult', { count: testResult }) }}
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'GeoSelector',

  data() {
    return {
      selectedRegion: '',
      selectedDepartment: '',
      selectedCommune: '',
      communeSearch: '',
      populationMin: '',
      populationMax: '',
      selectedCSP: '',

      regions: [],
      departments: [],
      communes: [],
      csps: [],

      testResult: null,
      loading: false,
    };
  },

  computed: {
    filteredDepartments() {
      if (!this.selectedRegion) return [];
      return this.departments.filter((dept) => dept.region_nom === this.selectedRegion);
    },

    hasSelection() {
      return this.selectedRegion || this.selectedDepartment || this.selectedCommune
             || this.populationMin || this.populationMax || this.selectedCSP;
    },
  },

  mounted() {
    this.loadRegions();
    this.loadDepartments();
    this.loadCSPs();
  },

  methods: {
    async loadRegions() {
      try {
        const response = await this.$http.get('/api/geo/regions');
        this.regions = response.data.data || [];
      } catch (error) {
        this.$buefy.toast.open({
          message: 'Erreur lors du chargement des régions',
          type: 'is-danger',
        });
      }
    },

    async loadDepartments() {
      try {
        const response = await this.$http.get('/api/geo/departements');
        this.departments = response.data.data || [];
      } catch (error) {
        this.$buefy.toast.open({
          message: 'Erreur lors du chargement des départements',
          type: 'is-danger',
        });
      }
    },

    async loadCSPs() {
      try {
        const response = await this.$http.get('/api/geo/csps');
        this.csps = response.data.data || [];
      } catch (error) {
        this.$buefy.toast.open({
          message: 'Erreur lors du chargement des CSP',
          type: 'is-danger',
        });
      }
    },

    onRegionChange() {
      this.selectedDepartment = '';
      this.selectedCommune = '';
      this.communeSearch = '';
      this.communes = [];
    },

    onDepartmentChange() {
      this.selectedCommune = '';
      this.communeSearch = '';
      this.communes = [];
    },

    async onCommuneSearch() {
      if (this.communeSearch.length < 2) {
        this.communes = [];
        return;
      }

      try {
        const params = {
          search: this.communeSearch,
        };

        if (this.selectedDepartment) {
          params.departement = this.selectedDepartment;
        }

        const response = await this.$http.get('/api/geo/communes', { params });
        this.communes = response.data.data || [];
      } catch (error) {
        this.$buefy.toast.open({
          message: 'Erreur lors de la recherche de communes',
          type: 'is-danger',
        });
      }
    },

    selectCommune(commune) {
      this.selectedCommune = commune.code_insee;
      this.communeSearch = commune.nom_commune;
      this.communes = [];
    },

    async testSelection() {
      if (!this.hasSelection) {
        this.$buefy.toast.open({
          message: 'Veuillez sélectionner au moins un critère',
          type: 'is-warning',
        });
        return;
      }

      this.loading = true;
      try {
        const params = this.buildGeoParams();
        const response = await this.$http.post('/api/lists/query/geo', params);

        this.testResult = response.data.data.count || 0;
      } catch (error) {
        this.$buefy.toast.open({
          message: 'Erreur lors du test de sélection',
          type: 'is-danger',
        });
      } finally {
        this.loading = false;
      }
    },

    applySelection() {
      if (!this.hasSelection) return;

      const params = this.buildGeoParams();
      this.$emit('input', params);

      this.$buefy.toast.open({
        message: 'Sélection géographique appliquée',
        type: 'is-success',
      });
    },

    buildGeoParams() {
      const params = {
        regions: [],
        departements: [],
        communes: [],
        codes_insee: [],
        csps: [],
        use_population: false,
      };

      if (this.selectedRegion) {
        params.regions.push(this.selectedRegion);
      }

      if (this.selectedDepartment) {
        params.departements.push(this.selectedDepartment);
      }

      if (this.selectedCommune) {
        params.codes_insee.push(this.selectedCommune);
      }

      if (this.selectedCSP) {
        params.csps.push(this.selectedCSP);
      }

      if (this.populationMin || this.populationMax) {
        params.use_population = true;
        if (this.populationMin) {
          params.population_min = parseInt(this.populationMin, 10);
        }
        if (this.populationMax) {
          params.population_max = parseInt(this.populationMax, 10);
        }
      }

      return params;
    },

    clearSelection() {
      this.selectedRegion = '';
      this.selectedDepartment = '';
      this.selectedCommune = '';
      this.communeSearch = '';
      this.populationMin = '';
      this.populationMax = '';
      this.selectedCSP = '';
      this.communes = [];
      this.testResult = null;

      this.$emit('input', '');
    },
  },
};
</script>

<style scoped>
.geo-selector {
  background: #f8f9fa;
  border: 1px solid #e9ecef;
  border-radius: 6px;
  padding: 1.5rem;
  margin: 1rem 0;
}

.geo-controls {
  display: grid;
  gap: 1rem;
}

.commune-results {
  max-height: 200px;
  overflow-y: auto;
  border: 1px solid #ddd;
  border-radius: 4px;
  background: white;
}

.commune-item {
  padding: 0.75rem;
  border-bottom: 1px solid #eee;
  cursor: pointer;
  transition: background-color 0.2s;
}

.commune-item:hover,
.commune-item:focus {
  background-color: #f5f5f5;
}

.commune-item:last-child {
  border-bottom: none;
}

.buttons {
  display: flex;
  gap: 0.5rem;
  flex-wrap: wrap;
}

.notification {
  margin-top: 1rem;
}

.help-text {
  font-size: 0.8rem;
  color: #666;
}

@media (max-width: 768px) {
  .geo-controls {
    grid-template-columns: 1fr;
  }
}
</style>
