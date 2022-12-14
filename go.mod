module github.com/hypnoglow/helm-s3

go 1.15

// See: https://github.com/helm/helm/issues/6994
replace github.com/docker/docker => github.com/moby/moby v0.7.3-0.20190826074503-38ab9da00309

require (
	github.com/Masterminds/semver v1.5.0
	github.com/Masterminds/semver/v3 v3.1.1
	github.com/aws/aws-sdk-go v1.43.16
	github.com/ghodss/yaml v1.0.0
	github.com/google/go-cmp v0.5.8
	github.com/minio/minio-go/v6 v6.0.40
	github.com/pkg/errors v0.9.1
	github.com/stretchr/testify v1.8.0
	gopkg.in/alecthomas/kingpin.v2 v2.2.6
	helm.sh/helm/v3 v3.10.3
	k8s.io/helm v2.17.0+incompatible
	sigs.k8s.io/yaml v1.3.0
)
